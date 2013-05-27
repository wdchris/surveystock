public class API_LeaderboardUser implements Comparable {
	public String firstName;
	public String lastName;
	public Decimal score;
	public String phone;
	public String email;
	public Integer answersCount; 
	
	public API_LeaderboardUser(String userFirstName, String userLastName, Decimal userScore, String userPhone, String userEmail, Integer userAnswersCount) {
		this.firstName = userFirstName;
		this.lastName = userLastName;
		this.score = userScore;
		this.phone = userPhone;
		this.email = userEmail;
		this.answersCount = userAnswersCount;
	}
	
	public String getName(){
		return firstName + ' ' + lastName;
	}
	
	public Integer compareTo(Object compareTo) {
    	API_LeaderboardUser compareToObj = (API_LeaderboardUser)compareTo;
    	if(this.score > compareToObj.score){
    		return -1;
    	} else if (compareToObj.score > this.score){
    		return 1;
    	}
    	
    	return this.getName().compareTo(compareToObj.getName());
	}
}