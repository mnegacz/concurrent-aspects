package pwr.concurrent.a.activeobject;

import static pwr.concurrent.PreconditionsUtils.preconditionsAreSatisfied;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import pwr.concurrent.PreconditionsUtils;
import pwr.concurrent.a.GenericPointcuts;
import pwr.concurrent.annotation.ActiveObject;
import pwr.concurrent.annotation.GuardedBy;

public abstract aspect ActiveObjectAspect {

	public pointcut activeObjectCreation(): execution((@ActiveObject *).new(..));

	public pointcut activeObjectMethodWithoutResultCall(): call(void (@ActiveObject *).*(..)) && !activeObjectMethodWithoutResultAndWithPreconditionsCall();

	public pointcut activeObjectMethodWithoutResultAndWithPreconditionsCall(): call(@GuardedBy void (@ActiveObject *).*(..));

	public pointcut activeObjectMethodCall(): call(Future (@ActiveObject *).*(..)) && !activeObjectMethodWithPreconditionsCall();

	public pointcut activeObjectMethodWithPreconditionsCall(): call(@GuardedBy Future (@ActiveObject *).*(..));

	private Map<Object, Scheduler> schedulers = new HashMap<>();

	after(ActiveObject annotation, Object thisObject): activeObjectCreation() && this(thisObject) && @this(annotation) {
		Scheduler scheduler = new Scheduler(annotation.terminateAfterMainMethod());

		synchronized (this) {
			schedulers.put(thisObject, scheduler);
		}

		ExecutorService executor = Executors.newSingleThreadExecutor();
		executor.submit(scheduler);
		executor.shutdown();
	}

	@SuppressWarnings("rawtypes")
	void around(final Object target): activeObjectMethodWithoutResultCall() && target(target) {
		MessageRequest messageRequest = new MessageRequest() {

			@Override
			public boolean guard() {
				return true;
			}

			@Override
			public void call() {
				proceed(target);
			}

		};

		registerRequest(target, messageRequest);
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	Object around(final Object target): activeObjectMethodCall() && target(target) {
		Future result = new Future();

		MessageRequest messageRequest = new MessageRequest(result) {

			@Override
			public boolean guard() {
				return true;
			}

			@Override
			public void call() {
				try {
					setFuture((Future) proceed(target));
				} catch (Throwable e) {
					setException(e);
				}
			}

		};

		registerRequest(target, messageRequest);
		return result;
	}

	@SuppressWarnings("rawtypes")
	void around(final GuardedBy annotation, final Object target): activeObjectMethodWithoutResultAndWithPreconditionsCall() && target(target) && @annotation(annotation) {
		Class<?> clazz = thisJoinPoint.getSignature().getDeclaringType();
		List<String> preconditionIds = Arrays.asList(annotation.value());

		final List<Method> preconditionMethods = PreconditionsUtils.extractPreconditionsMethod(clazz, preconditionIds);

		MessageRequest messageRequest = new MessageRequest() {

			@Override
			public boolean guard() {
				return preconditionsAreSatisfied(target, preconditionMethods);
			}

			@Override
			public void call() {
				proceed(annotation, target);
			}

		};

		registerRequest(target, messageRequest);
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	Object around(final GuardedBy annotation, final Object target): activeObjectMethodWithPreconditionsCall() && target(target) && @annotation(annotation) {
		Class<?> clazz = thisJoinPoint.getSignature().getDeclaringType();
		List<String> preconditionIds = Arrays.asList(annotation.value());

		final List<Method> preconditionMethods = PreconditionsUtils.extractPreconditionsMethod(clazz, preconditionIds);

		Future result = new Future();
		MessageRequest messageRequest = new MessageRequest(result) {

			@Override
			public boolean guard() {
				return preconditionsAreSatisfied(target, preconditionMethods);
			}

			@Override
			public void call() {
				try {
					setFuture((Future) proceed(annotation, target));
				} catch (Throwable e) {
					setException(e);
				}
			}

		};

		registerRequest(target, messageRequest);
		return result;
	}

	private void registerRequest(final Object target, MessageRequest<?> messageRequest) {
		synchronized (this) {
			Scheduler scheduler = schedulers.get(target);
			scheduler.enqueue(messageRequest);
		}
	}

	after(): GenericPointcuts.topLevelMainMethod() {
		synchronized (this) {
			for (Scheduler scheduler : schedulers.values()) {
				scheduler.terminateAfterMainMethod();
			}
		}
	}

}
