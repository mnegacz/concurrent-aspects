package pwr.concurrent.a.preconditions;

import static pwr.concurrent.PreconditionsUtils.extractPreconditionsMethod;
import static pwr.concurrent.PreconditionsUtils.preconditionsAreSatisfied;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.List;

import pwr.concurrent.annotation.EvaluatePreconditions;
import pwr.concurrent.annotation.WaitUntilPreconditions;

public abstract aspect PreconditionsAspect {

	public pointcut waitUntilPreconditions(WaitUntilPreconditions annotation): execution(@WaitUntilPreconditions * *(..)) && @annotation(annotation);

	public pointcut evaluatePreconditions(): execution(@EvaluatePreconditions * *(..));

	before(WaitUntilPreconditions annotation, Object target): waitUntilPreconditions(annotation) && target(target) {
		Class<?> clazz = thisJoinPoint.getSignature().getDeclaringType();
		List<String> preconditionIds = Arrays.asList(annotation.value());
		int waitingTime = annotation.waitingTime();

		List<Method> preconditionMethods = extractPreconditionsMethod(clazz, preconditionIds);

		synchronized (target) {
			while (!preconditionsAreSatisfied(target, preconditionMethods)) {
				try {
					target.wait(waitingTime);
				} catch (InterruptedException e) {
					throw new RuntimeException(e);
				}
			}
		}
	}

	after(Object target): evaluatePreconditions() && target(target) {
		synchronized (target) {
			target.notifyAll();
		}
	}

}
