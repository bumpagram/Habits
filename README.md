#  README хендмейд
—--
для демонстрации упражнения надо развернуть локальный мини-сервер (уже предоставлен) на localhost:8080. дальше задача сделать клиент соцсети по трекингу привычек. инфа по API внизу, ТЗ какой функционал должен быть - тоже. перегоняя по локалке данные туда сюда придется парсить джейсоны.
---

“In this unit, you learned how to use collection views to display data sets. You also learned about Swift generics, worked with diffable data sources to make dynamic updates easy, and explored the power of compositional layouts to create advanced designs. In this guided project, you'll build a simple social network client app that encourages the user to follow good habits by ranking them against other users.
As you did for the Restaurant project in the previous unit, you'll use a server that runs on your computer. Also, as in Restaurant, your focus will be on the user interface; the app's data is provided for you along with a simulation that models users interacting with the app over time.
”

“In this app, you're working with two primary types of data: habits and users. However, those are just the building blocks that enable the key feature of the app—keeping up with and encouraging other users.
Given this basic goal, you can start thinking about how to use the user interface to engage users in this social network.

Features
You'll need to enable your app's users to:
* View a list of habits.
* View a list of users.
* View the user statistics for a given habit.
* View the habit statistics for a given user.
* Log their habits and share them with the network”

-> (+1 screen = dashboard) ->
* Toggle the favorite status of a habit.
* Follow or unfollow a user.
* View summary information about favorite habits and followed users at a glance. 
————————————
“Controllers
The app will consist of one view controller for each of the screens above. You'll tie the four main screens together with a tab bar controller, and you'll use navigation controllers to display the detail screens. A tab bar controller provides convenient access to each section of the app, and it clearly communicates to the user that the screens exist.
”
“Networking
You'll place your networking code in its own set of protocols, extensions, and structs. This will keep its logic encapsulated and readily available to all the controllers that need it.
”
“Views
This app will use collection views in every screen. Some will present simple lists, while others will use sophisticated layouts. You'll put all your knowledge of collection views and compositional layouts to work to make a user interface that feels smooth, and you'll use diffable data sources to allow the interface to update in real time as the social network simulation runs.
”
“Models
Your model objects will all be structs that correspond to the various JSON types you receive from or post to the Habits web service. Note that these model objects often contain redundant copies. This is a common practice in web services when the extra cost of the redundant data is outweighed by the convenience of having everything you need returned by one call to the API”
————————
LOCAL SERVER: 
“The Habits folder included with this project contains a macOS app for the server, HabitServer.app.”
“To start and stop the server, click the button in the Server section on the left. If you make changes to server resource files, you'll need to stop and restart the server.
“The server app lets you edit users, habits, categories, and the active user, all of which are defined in JSON files. You can also open the images folder that contains user profile images. If you want to put your own images in this directory, make sure their format is PNG. Note that the profile image for a user is always named for the user's ID.
To verify that the server is functioning properly, make sure it is running, then open your browser and load the URL http://localhost:8080. The browser should display text that indicates the status of the server. If you receive an error, the most common cause is that one of the JSON files has an invalid format. You'll need to verify that the JSON data is valid, close the application window, and restart the server. You can use the Reset Data button to discard your custom data and restore the original files.
”

“Server Endpoints
For the Habits API service, every URL consists of http://localhost:8080 and one of the following endpoints:
/users:   A GET request to this endpoint will return a dictionary containing the users of the social network.
/habits:   A GET request to this endpoint will return a dictionary containing the habits a user can log.
/images:   Combined with the name of an image, a GET request to this endpoint will return the profile image associated with a user.
/userStats:   A GET request to this endpoint will return a summary of logged habits for all users. It can also be combined with a query parameter, ids, to return statistics for a subset of users.
/habitStats:   A GET request to this endpoint will return a summary of user logs for all habits. It can also be combined with a query parameter, names, to return statistics for a subset of habits.
/combinedStats:   A GET request to this endpoint will return a combined response comprising information from /userStats and /habitStats.
/userLeadingStats:   Combined with a user ID, a GET request to this endpoint will return user statistics containing just those habits in which the user is leading. If a user isn't leading in any habits, no statistics will be returned.
/loggedHabit:    A POST to this endpoint will log a new event related to one habit—the user's way of saying, for example, “I just took a walk.”

JSON Structure
To examine the JSON data from the API, you'll use a command-line tool called curl. Open the Terminal app, then type the following command to see the users:
 
curl localhost:8080/users
 
——————




