extends SceneTree

const Clock = preload("res://combat/combat_clock.gd")
const Order = preload("res://combat/combat_order.gd")
const Result = preload("res://combat/combat_result.gd")

## Calls CombatClock directly. No scene.


func _initialize() -> void:
	var failed: int = 0
	failed += _checked(_test_pause_holds_until_an_order())
	failed += _checked(_test_phases_share_one_timeline())
	failed += _checked(_test_second_blocker_holds_time())
	failed += _checked(_test_active_result_cancels_and_pauses())
	failed += _checked(_test_replace_becomes_wind_down())
	failed += _checked(_test_rejected_orders())
	if failed > 0:
		push_error("CombatClock tests failed: %d" % failed)
		quit(1)
		return
	print("CombatClock tests passed")
	quit(0)


func _test_pause_holds_until_an_order() -> int:
	var clock: Clock = Clock.new()
	var id: int = clock.add_participant(true)
	if not clock.is_paused():
		return _fail("a blocking waiter should pause")
	clock.tick(4)
	if clock.phase_of(id) != Clock.Phase.WAITING:
		return _fail("tick while paused should not leave waiting")
	var opened: Array = [0]
	var order: Order = Order.new(0, 1, 0, "payload", func(_clock: Clock, _id: int) -> Variant:
		opened[0] += 1
		return null
	)
	if not clock.submit_order(id, order):
		return _fail("order should be accepted from waiting")
	if clock.is_paused():
		return _fail("the only blocker has an order, so time can run")
	clock.tick(1)
	if opened[0] != 1 or clock.phase_of(id) != Clock.Phase.ADR:
		return _fail("zero start-up should open the active window on the first tick")
	if clock.time_left(id) != 1:
		return _fail("the active frame should still be unspent")
	return 0


func _test_phases_share_one_timeline() -> int:
	var clock: Clock = Clock.new()
	var id: int = clock.add_participant(true)
	var closed: Array = [0]
	var order: Order = Order.new(2, 1, 1, null, Callable(), func(_clock: Clock, _id: int) -> Variant:
		closed[0] += 1
		return null
	)
	clock.submit_order(id, order)
	clock.tick(1)
	if clock.phase_of(id) != Clock.Phase.STU or clock.time_left(id) != 1:
		return _fail("one frame of a two-frame start-up should remain")
	clock.tick(1)
	if clock.phase_of(id) != Clock.Phase.ADR or clock.time_left(id) != 1:
		return _fail("start-up should hand off to the active window")
	clock.tick(1)
	if closed[0] != 1 or clock.phase_of(id) != Clock.Phase.WND:
		return _fail("finishing the active length should close it and enter wind-down")
	clock.tick(1)
	if clock.phase_of(id) != Clock.Phase.WAITING or not clock.is_paused():
		return _fail("wind-down should return a blocker to waiting and pause")
	return 0


func _test_second_blocker_holds_time() -> int:
	var clock: Clock = Clock.new()
	var first: int = clock.add_participant(true)
	var second: int = clock.add_participant(true)
	clock.submit_order(first, Order.new(2, 1, 1))
	if not clock.is_paused():
		return _fail("the second human still needs an order")
	clock.tick(3)
	if clock.phase_of(first) != Clock.Phase.STU or clock.time_left(first) != 2:
		return _fail("a pause should keep the committed start-up")
	clock.submit_order(second, Order.new(2, 1, 1))
	if clock.is_paused():
		return _fail("both orders are in, so the frame can run")
	clock.tick(1)
	if clock.time_left(first) != 1 or clock.time_left(second) != 1:
		return _fail("both commitments should spend the same frame")
	return 0


func _test_active_result_cancels_and_pauses() -> int:
	var clock: Clock = Clock.new()
	var actor: int = clock.add_participant(true)
	var target: int = clock.add_participant(true)
	var actor_order: Order = Order.new(1, 1, 4, null, func(_clock: Clock, _id: int) -> Variant:
		return Result.cancel(target)
	)
	clock.submit_order(actor, actor_order)
	clock.submit_order(target, Order.new(3, 1, 4))
	clock.tick(1)
	if clock.phase_of(actor) != Clock.Phase.ADR or clock.time_left(actor) != 1:
		return _fail("the actor should be in the active window with its frame left")
	if clock.phase_of(target) != Clock.Phase.WAITING or not clock.is_paused():
		return _fail("cancelling a blocker should pause")
	clock.tick(2)
	if clock.time_left(actor) != 1 or clock.phase_of(actor) != Clock.Phase.ADR:
		return _fail("the pause should keep the active frame that was left")
	return 0


func _test_replace_becomes_wind_down() -> int:
	var clock: Clock = Clock.new()
	var actor: int = clock.add_participant(true)
	var target: int = clock.add_participant(false)
	clock.submit_order(actor, Order.new(1, 2, 4, null, func(_clock: Clock, _id: int) -> Variant:
		return Result.replace(target, 3)
	))
	clock.submit_order(target, Order.new(5, 1, 4))
	clock.tick(1)
	if clock.phase_of(target) != Clock.Phase.WND or clock.time_left(target) != 3:
		return _fail("replace should set wind-down frames")
	if clock.is_paused():
		return _fail("a non-blocking participant should not pause the clock")
	clock.tick(1)
	if clock.time_left(target) != 2:
		return _fail("replaced wind-down should spend with the timeline")
	return 0


func _test_rejected_orders() -> int:
	var clock: Clock = Clock.new()
	var id: int = clock.add_participant(true)
	if clock.submit_order(id, Order.new(-1, 1, 1)):
		return _fail("negative length should be rejected")
	if clock.phase_of(id) != Clock.Phase.WAITING:
		return _fail("a rejected order should leave the participant waiting")
	clock.submit_order(id, Order.new(2, 1, 1))
	if clock.submit_order(id, Order.new(2, 1, 1)):
		return _fail("a committed participant should not take another order")
	if not clock.submit_order(99, Order.new(1, 1, 1)):
		return 0
	return _fail("an unknown participant should reject the order")


func _checked(result: Variant) -> int:
	if result == 0:
		return 0
	return 1


func _fail(message: String) -> int:
	push_error(message)
	return 1
