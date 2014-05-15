package pwr.concurrent.a.asynchronous;

import static java.lang.Math.max;
import static java.util.concurrent.Executors.newSingleThreadExecutor;

import java.util.ArrayList;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import pwr.concurrent.a.GenericPointcuts;
import pwr.concurrent.annotation.JoinAfter;
import pwr.concurrent.annotation.JoinBefore;
import pwr.concurrent.annotation.Shutdown;
import pwr.concurrent.annotation.Startup;
import pwr.concurrent.annotation.ThreadPool;

public abstract aspect AsynchronousAspect {

	public pointcut startupThreadPool(Startup annotation): call(@Startup * *(..)) && @annotation(annotation);

	public pointcut shutdownThreadPool(Shutdown annotation): execution(@Shutdown * *(..)) && @annotation(annotation);

	public pointcut joinAfter(JoinAfter annotation): execution(@JoinAfter * *(..)) && @annotation(annotation);

	public pointcut joinBefore(JoinBefore annotation): execution(@JoinBefore * *(..)) && @annotation(annotation);

	public ExecutorService executorService;

	public boolean shutdownAfterMainExecution = true;

	private Map<Thread, ArrayList<Future<?>>> futures = new WeakHashMap<>();

	before(Startup annotation): startupThreadPool(annotation) {
		ThreadPool threadPool = annotation.threadPool();
		int maxThreads = annotation.maxThreads() > 0 ? annotation.maxThreads() : proposedThreadCount();
		int coreThread = annotation.coreThread() > 0 ? annotation.coreThread() : maxThreads / 3 + 1;
		int timeout = annotation.timeout() > 0 ? annotation.timeout() : proposedTimeout();

		synchronized (this) {
			shutdownAfterMainExecution = annotation.shutdownAfterMainMethod();
		}

		startupThreadPool(threadPool, maxThreads, coreThread, timeout);
	}

	private int proposedThreadCount() {
		return max(Runtime.getRuntime().availableProcessors() - 1, 1);
	}

	private int proposedTimeout() {
		return 60;
	}

	protected void startupThreadPool() {
		startupThreadPool(ThreadPool.CACHED, 0, 0, 0);
	}

	private void startupThreadPool(ThreadPool threadPool, int maxThreads, int coreThreads, int timeout) {
		synchronized (this) {
			if (executorService == null || executorService.isTerminated() || executorService.isShutdown()) {
				if (ThreadPool.FIXED.equals(threadPool)) {
					executorService = Executors.newFixedThreadPool(maxThreads);
				} else if (ThreadPool.CACHED.equals(threadPool)) {
					executorService = Executors.newCachedThreadPool();
				} else if (ThreadPool.CUSTOM.equals(threadPool)) {
					executorService = new ThreadPoolExecutor(coreThreads, maxThreads, timeout, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>());
				}
			}
		}
	}

	protected void registerFuture(Future<?> future) {
		synchronized (this) {
			ArrayList<Future<?>> threadFutures = null;
			if (futures.containsKey(Thread.currentThread())) {
				threadFutures = futures.get(Thread.currentThread());
			} else {
				threadFutures = new ArrayList<Future<?>>();
				futures.put(Thread.currentThread(), threadFutures);
			}
			threadFutures.add(future);
		}
	}

	before(JoinBefore annotation): joinBefore(annotation) {
		join();
	}

	after(JoinAfter annotation): joinAfter(annotation) {
		join();
	}

	private void join() {
		synchronized (this) {
			if (futures.containsKey(Thread.currentThread())) {
				ArrayList<Future<?>> threadFutures = futures.get(Thread.currentThread());
				for (Future<?> future : threadFutures) {
					try {
						future.get();
					} catch (InterruptedException | ExecutionException e) {
						throw new RuntimeException(e);
					}
				}
			}
		}
	}

	after(Shutdown annotation): shutdownThreadPool(annotation) {
		shutdown(annotation.now());
	}

	private void shutdown(boolean now) {
		synchronized (this) {
			if (executorService != null) {
				if (now) {
					executorService.shutdownNow();
				} else {
					executorService.shutdown();
				}
			}
		}
	}

	after(): GenericPointcuts.topLevelMainMethod() {
		synchronized (this) {
			if (shutdownAfterMainExecution) {
				shutdown(false);
			}
		}
	}

	protected Future<?> submitTask(boolean standalone, Callable<Object> task) {
		Future<?> future = null;
		if (standalone) {
			ExecutorService singleThreadexecutorService = newSingleThreadExecutor();
			future = singleThreadexecutorService.submit(task);
			singleThreadexecutorService.shutdown();
		} else {
			startupThreadPool();
			synchronized (task) {
				future = executorService.submit(task);
			}
		}
		return future;
	}

}
