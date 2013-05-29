public class TargetCalculator {
	public static Enums.Gender getGender(String title){		
		String lowerTitle = title.toLowerCase();
		if(lowerTitle == 'mr'){
			return Enums.Gender.MALE;
		} else if (lowerTitle == 'mrs' || lowerTitle == 'ms' || lowerTitle == 'miss') {
			return Enums.Gender.FEMALE;
		}
		
		return null;
	}

	public static Enums.AgeBand getAgeBand(Date birthDate){
		Integer age = getAge(birthDate);
		if(age != null){
			if(age < 20){
				return Enums.AgeBand.UNDER_TWENTY;
			} else if (age >= 20 && age < 30) {
				return Enums.AgeBand.TWENTY_TO_THIRTY;
			} else if (age >= 30 && age < 40) {
				return Enums.AgeBand.THIRTY_TO_FOURTY;
			} else if (age >= 40 && age < 50) {
				return Enums.AgeBand.FOURTY_TO_FIFTY;
			} else if (age >= 50 && age < 60) {
				return Enums.AgeBand.FIFTY_TO_SIXTY;
			} else if (age >= 60) {
				return Enums.AgeBand.OVER_SIXTY;
			}
		}
		
		return null;
	}
	
	public static Decimal getGenderValue(Survey_Target__c target, Enums.Gender gender) {
		if(target != null){
			// parse the gender and lookup value field from target
			if(gender == Enums.Gender.MALE){
				return calculateTargetValue(target.Male_Target__c, target.Male_Collected__c);
			} else if (gender == Enums.Gender.FEMALE) {
				return calculateTargetValue(target.Female_Target__c, target.Female_Collected__c);
			}
		}
		
		return 0;
	}
	
	public static Decimal getAgeValue(Survey_Target__c target, Date birthDate) {
		if(target != null){
			// parse the birthdate and lookup value field from target
			Enums.AgeBand age = getAgeBand(birthDate);
			if(age != null) {
				if(age == Enums.AgeBand.UNDER_TWENTY){
					return calculateTargetValue(target.Under_20_Target__c, target.Under_20_Collected__c);
				} else if(age == Enums.AgeBand.TWENTY_TO_THIRTY){
					return calculateTargetValue(target.Between_20_and_30_Target__c, target.Between_20_and_30_Collected__c);
				} else if(age == Enums.AgeBand.THIRTY_TO_FOURTY){
					return calculateTargetValue(target.Between_30_and_40_Target__c, target.Between_30_and_40_Collected__c);
				} else if(age == Enums.AgeBand.FOURTY_TO_FIFTY){
					return calculateTargetValue(target.Between_40_and_50_Target__c, target.Between_40_and_50_Collected__c);
				} else if(age == Enums.AgeBand.FIFTY_TO_SIXTY){
					return calculateTargetValue(target.Between_50_and_60_Target__c, target.Between_50_and_60_Collected__c);
				} else if(age == Enums.AgeBand.OVER_SIXTY){
					return calculateTargetValue(target.Over_60_Target__c, target.Over_60_Collected__c);
				}
			}
		}
		
		return 0;
	}
	
	public static Survey_Target__c setTargets(Survey_Target__c target, Enums.Gender gender, Date birthDate){
		// set gender targets
		if(gender == Enums.Gender.MALE){
			target.Male_Collected__c++;
		} else if (gender == Enums.Gender.FEMALE) {
			target.Female_Collected__c++;
		}
		
		// set age targets
		Enums.AgeBand age = getAgeBand(birthDate);
		if(age != null) {
			if(age == Enums.AgeBand.UNDER_TWENTY){
				target.Under_20_Collected__c++;
			} else if(age == Enums.AgeBand.TWENTY_TO_THIRTY){
				target.Between_20_and_30_Collected__c++;
			} else if(age == Enums.AgeBand.THIRTY_TO_FOURTY){
				target.Between_30_and_40_Collected__c++;
			} else if(age == Enums.AgeBand.FOURTY_TO_FIFTY){
				target.Between_40_and_50_Collected__c++;
			} else if(age == Enums.AgeBand.FIFTY_TO_SIXTY){
				target.Between_50_and_60_Collected__c++;
			} else if(age == Enums.AgeBand.OVER_SIXTY){
				target.Over_60_Collected__c++;
			}
		}
		
		return target;
	}
	
	public static API_SurveyTarget getApiTarget(Survey_Target__c target){
		API_SurveyTarget apitarget = new API_SurveyTarget();
		apitarget.locationName = target.Location_Name__c;
		
		// simple mapping from business to api object
		apitarget.targets.add(getApiSurveyTarget('Males', target.Male_Target__c, target.Male_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('Females', target.Female_Target__c, target.Female_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('Under 20 years old', target.Under_20_Target__c, target.Under_20_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('20 - 30 years old', target.Between_20_and_30_Target__c, target.Between_20_and_30_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('30 - 40 years old', target.Between_30_and_40_Target__c, target.Between_30_and_40_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('40 - 50 years old', target.Between_40_and_50_Target__c, target.Between_40_and_50_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('50 - 60 years old', target.Between_50_and_60_Target__c, target.Between_50_and_60_Collected__c));
		apitarget.targets.add(getApiSurveyTarget('Over 60 years old', target.Over_60_Target__c, target.Over_60_Collected__c));
		apitarget.targets.sort();
		
		return apitarget;
	}
	
	private static Decimal calculateTargetValue(Decimal target, Decimal collected){
		// formula to calculate value based on percentage left to complete
		if(target!= null && collected != null && target > 0 && collected < target){
			return ((target - collected)/target)*1000;
		}
		
		return 0;
	}
	
	private static Integer getAge(Date birthDate){
		if(birthDate != null){
			return birthDate.daysBetween(Date.today())/365;
		}
		
		return null;
	}
	
	private static API_SurveyTarget.Target getApiSurveyTarget(String name, Decimal target, Decimal collected){
		return new API_SurveyTarget.Target(name, calculateTargetValue(target, collected).round(), target, collected);
	}
}