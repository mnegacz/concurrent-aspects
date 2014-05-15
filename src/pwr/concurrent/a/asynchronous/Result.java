package pwr.concurrent.a.asynchronous;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import pwr.concurrent.Thrower;

public class Result<T> {

	private Future<T> future;

	private T data;

	private RecursiveTask<T> recursiveTask;

	private boolean available = false;

	public Result() {
		available = true;
	}

	public Result(T data) {
		this.data = data;
		available = true;
	}

	public Result(Future<T> future) {
		this.future = future;
	}

	public Result(RecursiveTask<T> task) {
		this.recursiveTask = task;
	}

	@SuppressWarnings("unchecked")
	public T get() {
		if (!available) {
			if (future != null) {
				try {
					Result<T> resultWrapper = (Result<T>) future.get();
					data = (T) resultWrapper.get();
					available = true;
				} catch (ExecutionException e) {
					Throwable cause = e.getCause();
					if (cause instanceof RuntimeException) {
						throw (RuntimeException) cause;
					} else if (cause instanceof Error) {
						throw (Error) cause;
					} else {
						Thrower.<RuntimeException> throwException(cause);
					}
				} catch (InterruptedException e) {
					throw new RuntimeException(e);
				}
			} else if (recursiveTask != null) {
				recursiveTask.fork();
				Result<T> resultWrapper = (Result<T>) recursiveTask.join();
				data = (T) resultWrapper.get();
				available = true;
			}
		}

		return data;
	}

	@SuppressWarnings("unchecked")
	public void scheduleWith(Result<T>... otherResults) {
		for (Result<T> otherResult : otherResults) {
			if (otherResult.recursiveTask != null) {
				otherResult.recursiveTask.fork();
			}
		}

		if (recursiveTask != null) {
			data = ((Result<T>) recursiveTask.compute()).data;
			available = true;
		}

		for (Result<T> otherResult : otherResults) {
			if (otherResult.recursiveTask != null) {
				Result<T> resultWrapper = (Result<T>) otherResult.recursiveTask.join();
				otherResult.data = resultWrapper.data;
				otherResult.available = true;
			}
		}
	}

}
