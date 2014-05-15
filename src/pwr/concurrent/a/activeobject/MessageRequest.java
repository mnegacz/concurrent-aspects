package pwr.concurrent.a.activeobject;

public abstract class MessageRequest<T> {

	private Future<T> result;

	public MessageRequest() {
	}

	public MessageRequest(Future<T> result) {
		this.result = result;
	}

	public abstract boolean guard();

	public abstract void call();

	protected void setFuture(Future<T> result) {
		this.result.setFuture(result);
	}

	protected void setException(Throwable exception) {
		this.result.setException(exception);
	}

}
