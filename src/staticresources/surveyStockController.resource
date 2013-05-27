function getLocalStorageObject(key) {
    var obj = localStorage[key];
    if (!isNull(obj)) {
        return JSON.parse(obj);
    }
 
    return null;
}

function setLocalStorageObject(key, obj){
	if (Modernizr.localstorage) {
		if(!isNull(obj)) {
			localStorage[key] =  JSON.stringify(obj);
		} else {
			localStorage[key] = null;
		}
	}
}

function onGetRemoteReturn(key, obj, e, callback) {
	if(e.status){    
		setLocalStorageObject(key, obj);
	} else if (Modernizr.localstorage) {
		obj = getLocalStorageObject(key);
	}
	
	if(!isNull(callback)){
		callback(obj);
	}	
}

function syncOffline() {
	// ping to check if we're back online, then attempt to save
	SurveyStockController.ping(function(time,e){
		if(e.status) {
			var surveys = getOfflineSurveyResults();
		    setLocalStorageObject("surveyresults", null);
		    for (var i = 0; i < surveys.length; i++) {
		        saveSurvey(surveys[i]);
		    }
		}
	}, {escape:true, timeout: 5000});
}

function getSurveys(callback) {
    SurveyStockController.getSurveys(function(surveys,e){
    	onGetRemoteReturn("surveys", surveys, e, callback);
    }, {escape:true});
}
 
function saveSurvey(survey) {
	SurveyStockController.setSurveyAnswers(survey, function(result,e){
		if(!e.status && Modernizr.localstorage) {
			 // store locally for now
	        var surveys = getOfflineSurveyResults();
	        surveys.push(survey);
	        setLocalStorageObject("surveyresults", surveys);
		}
	}, {escape:true});
}
 
function getOfflineSurveyResults() {
    var currentSurveys = getLocalStorageObject("surveyresults");
    return currentSurveys !== null ? currentSurveys : new Array();
}

function getSurveyQuestions(surveyId, callback) {
	var storageKey = 'surveyquestions_' + surveyId; 
	
	// get the local cache if available, else make remote call
	var localQuestions = getLocalStorageObject(storageKey);
	if(isNull(localQuestions)) {
		SurveyStockController.getSurveyQuestion(surveyId, function(questions,e){
	    	onGetRemoteReturn(storageKey, questions, e, callback);
	    }, {escape:true});
    } else if (!isNull(callback)) {
    	callback(localQuestions);
    }
}