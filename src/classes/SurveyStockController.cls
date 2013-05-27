public with sharing class SurveyStockController {
	@RemoteAction
	public static Datetime ping() {
		return datetime.now();
	}
	
    @RemoteAction
    public static List<Survey__c> getSurveys(){
        return [SELECT Id, Name__c 
                FROM Survey__c ORDER 
                BY Name];
    }
    
    @RemoteAction
    public static List<Survey_Question__c> getSurveyQuestion(String surveyId){
        return [SELECT TypeChoices__c, Question__c, QuestionType__c, Id 
                FROM Survey_Question__c 
                WHERE Survey__c = :surveyId];
    }
    
    @RemoteAction
    public static API_SurveyTarget getTargets(String surveyId, String latitude, String longitude) {
        Survey_Target__c target = getTarget(surveyId, latitude, longitude);
        if(target != null){
            return TargetCalculator.getApiTarget(target);
        }
        
        return null;
    }
    
    @RemoteAction
    public static List<API_LeaderboardUser> getLeaderboardUsers(String surveyId){
        // get user survey counts
		AggregateResult[] userSurveys = [SELECT CreatedById, count(Id) SurveyCount FROM Survey_Answer__c WHERE Survey__c =: surveyId GROUP BY CreatedById];
		
		// get all user details
        List<API_LeaderboardUser> users = new List<API_LeaderboardUser>();
        for(Leaderboard__c user: [SELECT User__c, Score__c FROM Leaderboard__c WHERE Survey__c =: surveyId]) {
            User usr = [SELECT FirstName, LastName, Phone, Email, Id FROM User WHERE Id =: user.User__c LIMIT 1];
            
            // lookup answer count
			Integer surveyAnswers = 0;
			for(AggregateResult ar : userSurveys) {
				if(ar.get('CreatedById') == usr.Id){
					surveyAnswers = (Integer)ar.get('SurveyCount');
				}
			}
            
            users.add(new API_LeaderboardUser(usr.FirstName, usr.LastName, user.Score__c.round(), usr.Phone, usr.Email, surveyAnswers));
        }
        
        users.sort();       
        return users;
    }
    
    @RemoteAction
    public static void setSurveyAnswers(API_SurveyAnswers answers){
        // add contact and survey to db
        Contact contact = addContact(answers);
        addSurveyAnswers(answers, contact);
        Enums.Gender gender = TargetCalculator.getGender(answers.title);
        
        // calculate score for the survey
        Survey_Target__c target = getTarget(answers.surveyId, answers.latitude, answers.longitude);
        Decimal surveyValue = TargetCalculator.getGenderValue(target, gender) + TargetCalculator.getAgeValue(target, contact.Birthdate);
    
        // update leaderboard
        Leaderboard__c leaderboard = getLeaderboard(answers.surveyId);
        if(leaderboard == null){
            leaderboard = new Leaderboard__c();
            leaderboard.User__c = UserInfo.getUserId();
            leaderboard.Survey__c = answers.surveyId;
            leaderboard.Score__c = surveyValue;
        } else {
            leaderboard.Score__c = leaderboard.Score__c + surveyValue;
        }
        
        upsert leaderboard;
            
        // update target
        if(target != null) {
            target = TargetCalculator.setTargets(target, gender, contact.Birthdate);
            update target;
        }
    }
    
    private static Leaderboard__c getLeaderboard(String surveyId){
        List<Leaderboard__c> results = [SELECT User__c, Survey__c, Score__c, Id
                                        FROM Leaderboard__c
                                        WHERE Survey__c =: surveyId AND User__c =: UserInfo.getUserId()
                                        LIMIT 1];
        if(!results.isEmpty()){
            return results[0];
        }
        
        return null;
    }
    
    private static Contact addContact(API_SurveyAnswers answers){
        Contact contact = new Contact();
        contact.FirstName = answers.firstName;
        contact.LastName = answers.lastName;
        contact.MailingPostalCode = answers.postcode;
        contact.Birthdate = date.parse(answers.birthDate);
        contact.Title = answers.title;
        
        insert contact;
        
        return contact;
    }
    
    private static void addSurveyAnswers(API_SurveyAnswers answers, Contact contact){
        Survey_Answer__c sa = new Survey_Answer__c();
        sa.Contact__c = contact.Id;
        sa.Survey__c = answers.surveyId;        
            
        if(answers.latitude != null && answers.latitude.length() > 0 && answers.longitude != null && answers.longitude.length() > 0) {
            sa.Location__Latitude__s = decimal.valueOf(answers.latitude);
            sa.Location__Longitude__s = decimal.valueOf(answers.longitude);
        }
        
        insert sa;
        
        for(API_SurveyAnswers.Answer answer: answers.answers){
            Survey_Question_Answer__c qa = new Survey_Question_Answer__c();
            qa.Survey_Answer__c = sa.Id;
            qa.Survey_Question__c = answer.questionId;
            qa.Answer__c = answer.answer;
            
            insert qa;
        }
    }
    
    private static Survey_Target__c getTarget(String surveyId, String latitude, String longitude) {
        // attempt to find target based on location
        List<Survey_Target__c> results;
        if(latitude != null && latitude.length() > 0 && longitude != null && longitude.length() > 0) {
            String q = 'SELECT Location_Name__c, Under_20_Target__c, Under_20_Collected__c, Survey__c, Over_60_Target__c, Over_60_Collected__c,' +
                    'Male_Target__c, Male_Collected__c, Id, Female_Target__c, Female_Collected__c, Between_50_and_60_Target__c,' + 
                    'Between_50_and_60_Collected__c, Between_40_and_50_Target__c, Between_40_and_50_Collected__c, Between_30_and_40_Target__c,' + 
                    'Between_30_and_40_Collected__c, Between_20_and_30_Target__c, Between_20_and_30_Collected__c ' + 
                    'FROM Survey_Target__c WHERE Survey__c =: surveyId ' +          
                    'AND DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'mi\') < 20 ' +
                    'ORDER BY DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'mi\') LIMIT 1';
                    
            results = Database.query(q);        
            if(!results.isEmpty()){
                return results[0];
            }
        }
        
        // pull out the location free target
        results =   [SELECT Location_Name__c, Under_20_Target__c, Under_20_Collected__c, Survey__c, Over_60_Target__c, Over_60_Collected__c,
                    Male_Target__c, Male_Collected__c, Id, Female_Target__c, Female_Collected__c, Between_50_and_60_Target__c,
                    Between_50_and_60_Collected__c, Between_40_and_50_Target__c, Between_40_and_50_Collected__c, Between_30_and_40_Target__c,
                    Between_30_and_40_Collected__c, Between_20_and_30_Target__c, Between_20_and_30_Collected__c
                    FROM Survey_Target__c 
                    WHERE Survey__c =: surveyId
                    AND location__latitude__s = null
                    AND location__longitude__s = null
                    ORDER BY id
                    LIMIT 1];
        
        if(!results.isEmpty()){
            return results[0];
        }
        
        return null;
    }
}