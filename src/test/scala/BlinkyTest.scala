package blinky

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class BlinkyTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "Blinky"

  it should "toggle LED at appropriate intervals" in {
    // For testing, we use a much smaller frequency to simulate quickly
    // freq = 10, so toggle every 5 cycles
    val testFreq = 10
    test(new Blinky(testFreq)).withAnnotations(Seq(VerilatorBackendAnnotation)) { c =>
      // Initial state
      c.io.led0.expect(false.B)

      // Step 4 cycles (cnt 0 -> 4)
      c.clock.step(4)
      c.io.led0.expect(false.B)

      // Step 1 cycle (cnt 4 -> 0, toggle)
      c.clock.step(1)
      c.io.led0.expect(true.B)

      // Step 5 cycles (cnt 0 -> 4, 4 -> 0)
      c.clock.step(5)
      c.io.led0.expect(false.B)
    }
  }
}
