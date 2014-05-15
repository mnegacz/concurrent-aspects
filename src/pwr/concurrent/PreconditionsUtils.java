package pwr.concurrent;

import java.lang.annotation.Annotation;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import pwr.concurrent.annotation.Precondition;

public class PreconditionsUtils {

	public static List<Method> extractPreconditionsMethod(Class<?> clazz, List<String> preconditionIds) {
		List<Method> preconditionMethods = new ArrayList<Method>();
		for (Method method : clazz.getDeclaredMethods()) {
			for (Annotation anno : method.getAnnotations()) {
				if (Precondition.class.equals(anno.annotationType()) && boolean.class.equals(method.getReturnType())) {
					if (preconditionIds.contains("all") || preconditionIds.contains(((Precondition) anno).value())) {
						method.setAccessible(true);
						preconditionMethods.add(method);
					}
				}
			}
		}
		return preconditionMethods;
	}

	public static boolean preconditionsAreSatisfied(Object target, List<Method> preconditionMethods) {
		boolean satisfied = true;
		for (Method method : preconditionMethods) {
			try {
				Object result = method.invoke(target);
				if (result instanceof Boolean) {
					satisfied = satisfied && (Boolean) result;
				}
			} catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
				e.printStackTrace();
			}
		}
		return satisfied;
	}

}
