package com.data.stream

import org.apache.flink.api.common.state.MapStateDescriptor
import org.apache.flink.api.common.typeinfo.BasicTypeInfo
import org.apache.flink.api.common.typeinfo.TypeHint
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.api.java.typeutils.ListTypeInfo

import org.apache.flink.streaming.api.functions.co.KeyedBroadcastProcessFunction
import org.apache.flink.util.Collector

class BroadcastProcess extends KeyedBroadcastProcessFunction[EventKey, Event, Rule, (Event, Rule)] {

    /**
      * 提前达到的 event，先保存下来
      */
    private val eventState = new MapStateDescriptor(
        "eventState",
        TypeInformation.of(new TypeHint[EventKey]() {}),
        TypeInformation.of(new TypeHint[Event]() {}))


    private val ruleStateDescriptor = new MapStateDescriptor(
        "RulesBroadcastState",
        TypeInformation.of(new TypeHint[RuleKey]() {}),
        TypeInformation.of(new TypeHint[Rule]() {}))

    override def processBroadcastElement(value: Rule, context: KeyedBroadcastProcessFunction[EventKey, Event, Rule, (Event, Rule)]#Context, collector: Collector[(Event, Rule)]): Unit = {
        context.getBroadcastState(ruleStateDescriptor).put(RuleKey(value.gateway, value.device), value)
    }

    override def processElement(in1: Event, readOnlyContext: KeyedBroadcastProcessFunction[EventKey, Event, Rule, (Event, Rule)]#ReadOnlyContext, collector: Collector[(Event, Rule)]): Unit = {
    }
}
