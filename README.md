surveystock
===========

My mobile app developed for Salesforce - the gamification of market research.

Repository code is taken from the Eclipse IDE layout and is composed of a single page (SurveyStock.page) along with several static JS resources. It also depends on custom objects such as Survey__C and APEX controllers for the remoting calls.

The app is hosted in the force.com interface and will require users to login first. It is possible to make this a more seemless experience by creating a site within force.com and then linking to TouchLogin.page. This will direct the user to a clean login page and then redirect back to the app once authenticated. All of this code is supplied in the repository.

In the Data folder, I have supplied some sample surveys with questions and targets. I have stripped out created/modified data as the username id's won't match a new database. I have also left out answers and leaderboards for the same reason.