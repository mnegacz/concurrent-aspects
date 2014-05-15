package pwr.concurrent.a.asynchronous;

import java.util.concurrent.Callable;
import java.util.concurrent.Future;

import net.sf.cglib.proxy.Enhancer;

import org.aspectj.lang.reflect.MethodSignature;

import pwr.concurrent.annotation.Asynchronous;

public abstract aspect AsynchronousWithResultProxyAspect extends AsynchronousAspect {

	public pointcut callAsynchronously(): call(@Asynchronous * *(..));

	Object around(final Asynchronous annotation): callAsynchronously() && !AsynchronousWithResultAspect.callAsynchronously() && !AsynchronousWithoutResultAspect.callAsynchronously() && @annotation(annotation) {
		Callable<Object> task = new Callable<Object>() {

			@Override
			public Object call() throws Exception {
				return proceed(annotation);
			}

		};

		Future<?> future = submitTask(annotation.standalone(), task);
		registerFuture(future);

		Enhancer enhancer = new Enhancer();
		enhancer.setSuperclass(((MethodSignature) thisJoinPoint.getSignature()).getReturnType());
		enhancer.setCallback(new FutureLazyLoader(future));
		return enhancer.create();
	}

}