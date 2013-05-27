
function formatNumber(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function isNull(obj) {
    return (typeof (obj) === 'undefined' || obj === null || obj === 'null');
}

function hideLoading() {
	$j.mobile.loading('hide');
}

function initMainPage(){
	getSurveys(function(surveys){setSurveys(surveys)});

	if (Modernizr.geolocation){
    	navigator.geolocation.getCurrentPosition(function(pos){    		
    		sessionStorage.latitude = pos.coords.latitude;
    		sessionStorage.longitude = pos.coords.longitude;
    	});
    } else {
    	sessionStorage.latitude = '';
		sessionStorage.longitude = '';
    }
    
    // set a timer to check for offline cache
    setInterval(syncOffline, 60000);
}

function setSurveys(surveys){
	var options = $j('#selectSurveys');
	options.empty();
	
	var index = 0;
	var selectedIndex = 0;
	$j.each(surveys, function(){
		var option = $j('<option />').val(this.Id).text(this.Name__c);
		if(sessionStorage.surveyId === this.Id){
			selectedIndex = index;
			option.attr('selected', 'selected');
		}
		options.append(option);
	
	
		/*
		var optionHtml = '<option value="' + this.Id + '"';
		if(sessionStorage.surveyId === this.Id){
			optionHtml += ' selected="selected"';
			selectedIndex = index;
		}		
	 	optionHtml += '>' + this.Name__c + '</option>';
		options.append(optionHtml);
		*/
		
		index++;
	});
	
	options.selectedIndex = selectedIndex;
	options.selectmenu('refresh');
	
	options.change(function(){
		sessionStorage.surveyId = $j('#selectSurveys option:selected')[0].value;		
	});
	
	sessionStorage.surveyId = $j('#selectSurveys option')[selectedIndex].value
}

function initSurveyPage() {
	var dayOptions = $j('#selectDay');
	dayOptions.empty();
	for(var i=1;i<=31;i++) {
		dayOptions.append($j("<option />").val(i).text(i));
	}
	dayOptions.selectmenu('refresh', true);
	
	var yearOptions = $j('#selectYear');
	yearOptions.empty();
	var currentYear = new Date().getFullYear();
	for(var j=0;j<=100;j++) {
		yearOptions.append($j("<option />").val(currentYear - j).text(currentYear - j));
	}
	yearOptions.selectmenu('refresh', true);
	
	$j('#buttonSave').click(function(){
		var birthMonth = $j('#selectMonth option:selected')[0].value;
		var birthDay = $j('#selectDay option:selected')[0].value;
		var birthYear = $j('#selectYear option:selected')[0].value;
	
		var answersJson = {
			firstName: $j('#textForename').val(), 
			lastName: $j('#textSurname').val(),
			postcode: $j('#textPostcode').val(),
			birthDate: birthDay + '/' + birthMonth + '/' + birthYear,
			title: $j('#selectTitle option:selected')[0].value,
			latitude: sessionStorage.latitude,
			longitude: sessionStorage.longitude,
			surveyId: $j('#selectSurveys option:selected')[0].value,
			answers: getSurveyAnswers()		
		};
		saveSurvey(answersJson);
	});
}

function beforeSurveyShown() {
	$j('#questions').empty();
	$j('#surveypage').find('input').each(function(){this.value = ''});
	$j('#surveypage').find('select').each(function(){
    	this.selectedIndex = 0;
    	$j(this).selectmenu('refresh', true);
	});
}

function surveyShown() {
	$j.mobile.loading('show');
	getSurveyQuestions(sessionStorage.surveyId, function(questions) {setSurveyQuestions(questions, hideLoading)});
}

function setSurveyQuestions(questions, callback) {
	var questionDiv = $j('#questions');
	$j.each(questions, function(){
		if(this.QuestionType__c === "Text") {
			questionDiv.append($j('<div />').attr('questionId',this.Id).attr('questiontype','text')
						.append($j('<label />').attr('for',this.Id).html(this.Question__c + ':'))
						.append($j('<input />').attr('type','text').attr('name',this.Id).attr('id',this.Id)));
		} else if (this.QuestionType__c === "Choice") {
			var options = 	$j.map(this.TypeChoices__c.split(","), function(choice) {
								return $j('<option />').val(choice.trim()).text(choice.trim());
							});
		
			questionDiv.append($j('<div />').attr('questionId',this.Id).attr('questiontype','choice')
						.append($j('<label />').attr('for',this.Id).html(this.Question__c + ':'))
						.append($j('<select />').attr('name',this.Id).attr('id',this.Id)
							.append(options)));
		}
	});
	questionDiv.trigger("create");
	
	if(callback != null){
		callback();
	}
}

function getSurveyAnswers() {
	var answers = [];
	$j('#questions').children().each(function(){
		var questionDiv = $j(this);
		var answer;
		if(questionDiv.attr('questiontype') === "text"){
			answer = questionDiv.find('input')[0].value;
		} else if(questionDiv.attr('questiontype') === "choice"){
			answer = questionDiv.find('select option:selected')[0].value;
		}
	
		answers.push({
			questionId: questionDiv.attr('questionid'),
			answer: answer
		});
	});
	return answers;
}

function beforeTargetShown() {
	$j('#targetLocationName').empty();
	$j('#targetDiv').empty();
}

function targetShown() {
	$j.mobile.loading('show');
	SurveyStockController.getTargets(sessionStorage.surveyId,sessionStorage.latitude,sessionStorage.longitude,function(targets,e){setTargets(targets, hideLoading)}, {escape:true});
}

function setTargets(target, callback){
	var targetDiv = $j('#targetDiv');
	if(target == null){
		$j('#targetLocationName').html('No target data');
	} else {
		$j('#targetLocationName').html(target.locationName);
		$j.each(target.targets, function(){			
			targetDiv.append($j('<div/>').attr('data-role','collapsible').attr('data-content-theme','d')
						.append($j('<h3/>')
							.append($j('<div/>').attr('class','ui-grid-a')
								.append($j('<div/>').attr('class','ui-block-a').attr('style','width: 80%')
									.html(this.name))
								.append($j('<div/>').attr('class','ui-block-b').attr('style','width: 20%')
									.html(formatNumber(this.value) + 'pts'))))
						.append($j('<p/>').html('Target: ' + this.target))
						.append($j('<p/>').html('Collected: ' + this.collected)));
		});
		
		targetDiv.trigger( "create" );
	}
	
	if(callback != null){
		callback();
	}
}

function beforeLeaderboardShown() {
	$j('#leaderboardDiv').empty();
}

function leaderboardShown() {
	$j.mobile.loading('show');
	SurveyStockController.getLeaderboardUsers(sessionStorage.surveyId,function(users,e){setLeaderboard(users, hideLoading);}, {escape:true});
}

function setLeaderboard(users, callback) {
	var leaderboardDiv = $j('#leaderboardDiv');
	if(users == null || users.length == 0){
		leaderboardDiv.html($j('<h2/>').html('No leaderboard data'));
	} else {	
		var place = 1;
		$j.each(users, function(){			
			leaderboardDiv.append($j('<div/>').attr('data-role','collapsible').attr('data-content-theme','d')
							.append($j('<h3/>')
								.append($j('<div/>').attr('class','ui-grid-a')
									.append($j('<div/>').attr('class','ui-block-a').attr('style','width: 70%')
										.html(place + '. ' + this.firstName + ' ' + this.lastName))
									.append($j('<div/>').attr('class','ui-block-b').attr('style','width: 30%')
										.html(formatNumber(this.score)))))
							.append($j('<p/>').html('Completed Surveys: ' + this.answersCount))
							.append($j('<p/>').html('Telephone: ' + (typeof(this.phone) === 'undefined' ? '-' : this.phone)))
							.append($j('<p/>').html('Email: ' + (typeof(this.email) === 'undefined' ? '-' : this.email))));
			
			place++;
		});
	
		leaderboardDiv.trigger( "create" );
	}
	
	if(callback != null){
		callback();
	}
}