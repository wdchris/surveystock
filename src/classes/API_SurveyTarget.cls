public class API_SurveyTarget {
	public String locationName;
	public List<Target> targets;
	
	public API_SurveyTarget() {
		targets = new List<Target>();
	}
	
	public class Target implements Comparable{
		public String name;
		public Decimal value;
		public Decimal target;
		public Decimal collected;
		
		public Target(String targetName, Decimal targetValue, Decimal targetTarget, Decimal targetCollected) {
			this.name = targetName;
			this.value = targetValue;
			this.target = targetTarget;
			this.collected = targetCollected;
		}
		
		public Integer compareTo(Object compareTo) {
	    	Target compareToObj = (Target)compareTo;
	    	if(this.value > compareToObj.value){
	    		return -1;
	    	} else if (compareToObj.value > this.value){
	    		return 1;
	    	}
	    	
	    	return this.name.compareTo(compareToObj.name);
		}
	}
}