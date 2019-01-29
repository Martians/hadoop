package com.data.stream

import java.util

import org.apache.flink.api.common.accumulators.LongCounter
import org.apache.flink.api.common.state._
import org.apache.flink.api.common.typeinfo.TypeHint
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.configuration.Configuration
import org.apache.flink.runtime.state.{FunctionInitializationContext, FunctionSnapshotContext}
import org.apache.flink.streaming.api.checkpoint.CheckpointedFunction
import org.apache.flink.streaming.api.functions.co.KeyedBroadcastProcessFunction
import org.apache.flink.util.Collector
import org.slf4j.LoggerFactory

import scala.collection.mutable.Map
import scala.collection.mutable.ListBuffer

/**
  *     https://ci.apache.org/projects/flink/flink-docs-release-1.7/dev/stream/state/broadcast_state.html
  *
  * 难点：
  *     1. broadcast 流比 keystream更早到达
  *         1）需要先保留，等到rule达到时，判断保存的Event是否需要报警
  *         2）如果保留的Event超过了限制，需要退出程序
  */
class BroadcastProcess(config: FlinkConfig, ruleSource: RuleSource) extends KeyedBroadcastProcessFunction[EventKey, Event, Rule, (Event, Rule)] with CheckpointedFunction {
    private val log = LoggerFactory.getLogger(this.getClass)

    val rules = new LongCounter
    val total = new LongCounter
    val dangling = new LongCounter
    val notified = new LongCounter

    private val ruleStateDescriptor = ruleSource.ruleStateDescriptor
    private var listEvent: ListState[Map[EventKey, ListBuffer[Event]]] = _

    override def snapshotState(functionSnapshotContext: FunctionSnapshotContext): Unit = {
    }

    override def initializeState(context: FunctionInitializationContext): Unit = {
        val descriptor = new ListStateDescriptor("eventSave",
            TypeInformation.of(new TypeHint[Map[EventKey, ListBuffer[Event]]]() {}))

        /**
          * 提前达到的 event，先保存下来
          *     目前只能使用list结构
          */
        listEvent = context.getOperatorStateStore.getListState(descriptor)
        listEvent.add(Map[EventKey, ListBuffer[Event]]())
    }

    @throws[Exception]
    override def open(parameters: Configuration): Unit = {
        super.open(parameters)

        getRuntimeContext.addAccumulator("rules", rules)
        getRuntimeContext.addAccumulator("total", total)
        getRuntimeContext.addAccumulator("notified", notified)
        getRuntimeContext.addAccumulator("dangling", dangling)
    }

    def getList(key: EventKey, create: Boolean = false, delete: Boolean = false) = {
        val map = listEvent.get().iterator().next()
        var result = map.get(key)
        if (result.isEmpty && create) {
            map += (key -> ListBuffer[Event]())
            result = map.get(key)
        }
        if (delete) {
            map.remove(key)
            None
        } else {
            result
        }
    }

    override def processBroadcastElement(rule: Rule, context: KeyedBroadcastProcessFunction[EventKey, Event, Rule, (Event, Rule)]#Context, collector: Collector[(Event, Rule)]): Unit = {
        context.getBroadcastState(ruleStateDescriptor).put(RuleKey(rule.gateway, rule.device), rule)
        rules.add(1)

        val key = EventKey(rule.gateway, rule.device)
        val list = getList(key)
        if (!list.isEmpty) {
            val result = list.get
            dangling.add(-result.size)
            result.foreach(x => {
                if (notify(x, rule)) {
                    collector.collect((x, rule))
                }
            })

            log.info("================ get rule {}, release [{}] event, total remain [{}]", Array[AnyRef](rule, result.size.toString, rules.getLocalValue.toString): _*)
            getList(key, false, true)

        } else {
            log.info("================ get rule {}", rule)
        }
    }

    override def processElement(event: Event, readOnlyContext: KeyedBroadcastProcessFunction[EventKey, Event, Rule, (Event, Rule)]#ReadOnlyContext, collector: Collector[(Event, Rule)]): Unit = {
        total.add(1)

        val context = readOnlyContext.getBroadcastState(ruleStateDescriptor)
        var rule = context.get(RuleKey(event.gateway_id, event.device_id))

        if (rule == null) {
            dangling.add(1)
            if (dangling.getLocalValue() > config.unordered) {
                log.warn("wait unordered event, exceed {}, maybe database not start!", dangling.getLocalValue())
                System.exit(-1)
            }

            var result = getList(EventKey(event.gateway_id, event.device_id), true).get
            result += event

            log.info("can't find rule for {}, wait for later rule, current wait total {}", Array[AnyRef](event, result.size.toString): _*)

        } else if (notify(event, rule)) {
            collector.collect((event, rule))
        }
    }

    def notify(event: Event, rule: Rule): Boolean = {
        val real = event.real_data.toFloat
        val upper = rule.upper.toFloat
        val lower = rule.lower.toFloat

        if (real < lower || real > upper) {
            if (config.logging) {
                log.info("match rule, event<{}>, rule[{}]", Array[AnyRef](event, rule): _*)
            }
            notified.add(1)
            true
        } else {
            false
        }
    }

}
