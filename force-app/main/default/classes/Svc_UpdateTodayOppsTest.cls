@isTest
public class Svc_UpdateTodayOppsTest {
	@isTest
	public static void schedulableTest(){
		Svc_UpdateTodayOppsSchedulable.scheduleJob();
		Svc_UpdateTodayOppsSchedulable.cancel();
		Svc_UpdateTodayOppsSchedulable.worker();
	}
}