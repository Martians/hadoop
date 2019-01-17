package com.data;

import io.prometheus.client.Gauge;

public class Guage extends Counter {

  static final Gauge gauge = Gauge.build()
      .name("test_gauge").help("Inprogress requests.").register();

  static final Gauge gauge_speed = Gauge.build()
      .name("test_gauge_speed")
      .labelNames("speed")
      .help("Inprogress requests.").register();

  /**
   * speed: test_gauge_speed
   */
  void working() {
    gauge.setToCurrentTime();

    gauge_speed.labels("speed").set(rand(10));
  }

  public static void main(String[] args) {
    Counter client = new Counter();
    client.startServer();
  }
}
