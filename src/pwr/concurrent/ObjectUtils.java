package pwr.concurrent;

import static java.lang.System.identityHashCode;

public class ObjectUtils {

	public static String getObjectReferenceAsString(Object object) {
		return object.getClass().getName() + "@" + Integer.toHexString(identityHashCode(object));
	}

}
