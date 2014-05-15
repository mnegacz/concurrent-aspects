package pwr.concurrent.a.asynchronous;

import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.ForkJoinTask;

import net.sf.cglib.proxy.Enhancer;

import org.aspectj.lang.reflect.MethodSignature;

import pwr.concurrent.annotation.AsynchronousRecursively;

public abstract aspect AsynchronousRecursivelyWithProxyAspect {

	pointcut callAsynchronously(): call(@AsynchronousRecursively * *(..));

	pointcut outerCall(): callAsynchronously() && !cflowbelow(callAsynchronously());

	pointcut innerCall(): callAsynchronously() && cflowbelow(callAsynchronously());

	Object around(final AsynchronousRecursively annotation) : outerCall() && !AsynchronousRecursivelyAspect.outerCall() && @annotation(annotation) {
		ForkJoinPool forkJoinPool = null;

		if (annotation.threads() > 0) {
			forkJoinPool = new ForkJoinPool(annotation.threads());
		} else {
			forkJoinPool = new ForkJoinPool();
		}

		RecursiveTask<Object> task = new RecursiveTask<Object>() {
			private static final long serialVersionUID = 2L;

			@Override
			public Object compute() {
				return proceed(annotation);
			}

		};

		ForkJoinTask<Object> forkJoinTask = forkJoinPool.submit(task);
		Enhancer enhancer = new Enhancer();
		enhancer.setSuperclass(((MethodSignature) thisJoinPoint.getSignature()).getReturnType());
		enhancer.setCallback(new FutureLazyLoader(forkJoinTask));
		return enhancer.create();
	}

	Object around() : innerCall() && !AsynchronousRecursivelyAspect.innerCall() {
		RecursiveTask<Object> task = new RecursiveTask<Object>() {
			private static final long serialVersionUID = 3L;

			@Override
			public Object compute() {
				return proceed();
			}

		};

		Enhancer enhancer = new Enhancer();
		enhancer.setSuperclass(((MethodSignature) thisJoinPoint.getSignature()).getReturnType());
		enhancer.setCallback(new RecursiveTaskLazyLoader(task));
		return enhancer.create();
	}

}
