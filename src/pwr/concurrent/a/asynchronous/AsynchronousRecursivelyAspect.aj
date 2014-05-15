package pwr.concurrent.a.asynchronous;

import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.ForkJoinTask;

import pwr.concurrent.annotation.AsynchronousRecursively;

public abstract aspect AsynchronousRecursivelyAspect {

	pointcut callAsynchronously(): call(@AsynchronousRecursively Result *(..));

	pointcut outerCall(): callAsynchronously() && !cflowbelow(callAsynchronously());

	pointcut innerCall(): callAsynchronously() && cflowbelow(callAsynchronously());

	Object around(final AsynchronousRecursively annotation) : outerCall() && @annotation(annotation) {
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

		ForkJoinTask<Object> submit = forkJoinPool.submit(task);
		return new Result<>(submit);
	}

	Object around() : innerCall() {
		RecursiveTask<Object> task = new RecursiveTask<Object>() {
			private static final long serialVersionUID = 3L;

			@Override
			public Object compute() {
				return proceed();
			}

		};

		return new Result<>(task);
	}

}
