package pwr.concurrent.a.activeobject;

import pwr.concurrent.Thrower;

public class Future<T> {

	private T data;
	
	private boolean available = false;
	
	private Throwable exception;
	
	public Future() {
	}
	
	public Future(T data) {
		this.data = data;
	}

	public boolean isAvailable() {
		return available;
	}
	
	public T get() {
		synchronized (this) {
			while(!available) {
				try {
					wait();
				} catch (InterruptedException e) {
					throw new RuntimeException(e);
				}
			}	
		}
		
		if (exception != null) {
			Thrower.<RuntimeException>throwException(exception);
		}
		
		return data;
	}
	
	void setFuture(Future<T> future) {
		synchronized (this) {
			this.data = future.data;
			available = true;
			notifyAll();			
		}
	}
	
	void setException(Throwable exception) {
		synchronized (this) {
			this.exception = exception;
			available = true;
			notifyAll();			
		}
	}

}
