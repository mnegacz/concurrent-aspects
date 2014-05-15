package pwr.concurrent.a;

public aspect GenericPointcuts {

	public pointcut mainMethod(): execution(public static void *.main(String[]));

	public pointcut topLevelMainMethod(): mainMethod() && !cflowbelow(mainMethod());

}
