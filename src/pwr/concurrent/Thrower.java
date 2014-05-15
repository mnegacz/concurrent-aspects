package pwr.concurrent;

public class Thrower {

	@SuppressWarnings("unchecked")
	public static <T extends Throwable> void throwException(Throwable exception) throws T {
		throw (T) exception;
	}

}
