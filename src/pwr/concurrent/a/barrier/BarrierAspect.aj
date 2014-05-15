package pwr.concurrent.a.barrier;

import static pwr.concurrent.ObjectUtils.getObjectReferenceAsString;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;

import org.aspectj.lang.JoinPoint;

import pwr.concurrent.annotation.BarrierAfter;
import pwr.concurrent.annotation.BarrierBefore;

public abstract aspect BarrierAspect {

	public pointcut barierBefore(BarrierBefore annotation): execution(@BarrierBefore * *(..)) && @annotation(annotation);

	public pointcut barierAfter(BarrierAfter annotation): execution(@BarrierAfter * *(..)) && @annotation(annotation);

	private Map<String, CyclicBarrier> barriers = new HashMap<>();

	before(BarrierBefore annotation): barierBefore(annotation) {
		applyBarrier(getKey(annotation.name(), null, thisJoinPoint), annotation.value());
	}

	before(BarrierBefore annotation, Object target): barierBefore(annotation) && target(target) {
		applyBarrier(getKey(annotation.name(), target, thisJoinPoint), annotation.value());
	}

	private String getKey(String name, Object target, JoinPoint joinPoint) {
		String key = null;
		if (target == null) {
			key = joinPoint.getSignature().getDeclaringTypeName();
		} else {
			key = getObjectReferenceAsString(target);
		}
		if ("thisMethod".equals(name)) {
			key += "." + joinPoint.getSignature().getName();
		} else if (!"this".equals(name)) {
			key = "custom:" + name;
		}
		return key;
	}

	private void applyBarrier(String key, int parties) {
		CyclicBarrier cyclicBarrier = getBarrier(key, parties);
		try {
			cyclicBarrier.await();
		} catch (InterruptedException | BrokenBarrierException e) {
			throw new RuntimeException(e);
		}
	}

	private CyclicBarrier getBarrier(String key, int parties) {
		CyclicBarrier cyclicBarrier = null;
		synchronized (this) {
			if (barriers.containsKey(key)) {
				cyclicBarrier = barriers.get(key);
			} else {
				cyclicBarrier = new CyclicBarrier(parties);
				barriers.put(key, cyclicBarrier);
			}
		}
		return cyclicBarrier;
	}

	after(BarrierBefore annotation): barierBefore(annotation) {
		applyBarrier(getKey(annotation.name(), null, thisJoinPoint), annotation.value());
	}

	after(BarrierBefore annotation, Object target): barierBefore(annotation) && target(target) {
		applyBarrier(getKey(annotation.name(), target, thisJoinPoint), annotation.value());
	}

}
