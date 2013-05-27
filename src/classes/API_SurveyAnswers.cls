public class API_SurveyAnswers {
	// contact info
	public String firstName;
	public String lastName;
	public String postcode;
	public String birthDate;
	public String title;
	
	// geolocation
	public String latitude;
	public String longitude;
	
	// survey info
	public String surveyId;
	public List<Answer> answers;
	
	public class Answer{
		public String questionId;
		public String answer;
	}
	
	public API_SurveyAnswers(){
		answers = new List<Answer>();
	}
}