import http.requests.GetRequest;
import java.util.List;

// All the objects declared on top of the program are global, and thus can be accessible in the entire program.

// Api url constants
final String STREAMS_BASE_URL = "https://api.twitch.tv/helix/streams?";
final String USERS_BASE_URL = "https://api.twitch.tv/helix/users?";
final String TWITCH_BASE_URL = "https://www.twitch.tv/";

// Twitch token: it has to be your own. This one is valid but won't work if too many people use it. 
final String TWITCH_TOKEN = "048o30kiq54suyv43jio7boaknv8e2";

// Refresh interval between two streams requests, in milliseconds.
final int WAIT_TIME = 10 * 1000; // could be faster, but requests slow the app (synchronous)

// Usernames array. Array, not List, because of the loadStrings method
String usernames[];

// streamerData contains only found streamers. 
List<Streamer> streamerData = new ArrayList();

// Stores time, used to trigger the api requests
int startTime;

//tkf background
PImage tkf;

// Setup method. Run once when the program starts.
void setup() {
  startTime = millis();
  size(960, 540);
  background(255);

  usernames = loadStrings("usernames.txt");

  if (usernames == null) {
    println("Property file is missing");
    exit();
  }

  try {
    GetRequest get = new GetRequest(getUrlWithQueryParams(USERS_BASE_URL, "login"));
    get.addHeader("Client-ID", TWITCH_TOKEN);
    get.send();

    JSONArray jsonData = parseJSONObject(get.getContent()).getJSONArray("data");

    // loop on the size of the response instead of users.length in case some users were not found
    for (int index=0; index<jsonData.size(); index++) {
      Streamer streamer = new Streamer(jsonData.getJSONObject(index));
      streamerData.add(streamer);
    }
  }
  catch(Exception e) {
    println("Failed to get basic data of your streamers");
    exit();
  }

  tkf= loadImage("TKF_LOGO.jpg");

  PFont Russo_One;
  // The font "RussoOne.ttf" must be located in the 
  // current sketch's "data" directory to load successfully
  Russo_One = createFont("Russo_One.ttf", 32);
  background(0);
  textFont(Russo_One);
}

void draw() {
  background(0);
  stroke(255);
  strokeWeight(4);
  noFill();
  //image(tkf, 460, 290, 500, 250);
  tint(255, 126);
  image(tkf,130, 95,700,350);
  

  // Update the streamerData
  if (clockTick()) {

    try {
      GetRequest get = new GetRequest(getUrlWithQueryParams(STREAMS_BASE_URL, "user_login"));
      get.addHeader("Client-ID", TWITCH_TOKEN);
      get.send();

      JSONObject json  = parseJSONObject(get.getContent());
      JSONArray data = json.getJSONArray("data");

      for (Streamer user : streamerData) {
        user.isStreaming = false;
        for (int index = 0; index<data.size(); index++) {
          if (data.getJSONObject(index).get("user_id").equals(user.userId)) {
            user.isStreaming = true;
            user.thumbnailUrl = data.getJSONObject(index).get("thumbnail_url").toString();
            user.setThumbnail(user.thumbnailUrl);
            user.streamTitle = data.getJSONObject(index).get("title").toString();
          }
        }
      }
      startTime = millis();
    }

    catch(Exception e) {
      println("Failed to get stream data for your streamers");
    }
  }

  // Streaming status display, with red/green lights.
  int livenum=-1;//zero index of how many streamers are live. 0=1 ya know
  for (int index=0; index<streamerData.size(); index++) {
    strokeWeight(2); 
    int X;//left justification of streamer list
    int num;//streamer list can fit 2 columns of 9. num equals row number
    noTint();  // Disable tint
    if (streamerData.get(index).isStreaming) {
      livenum+=1;//if streamer is live mark it as live streamer zero index
      if (livenum<=9) {//if less than or equal to 9 justify to the left and use rows 1-9
        X=70;
        num=livenum;//if more than 9 justify to the middle and use rows 1-8 by subtracting 9 from livenum
      } else {
        X=width/2+70;
        num=livenum-9;
      }      
      textSize(14);//big name
      String Strimmer=streamerData.get(index).displayName;//strimmer name
      text( Strimmer, X, 60*num+15);//place name
      float StrimmerSize=textWidth(Strimmer);//figure out how big the name is
      textSize(12);//small title
      text(" is streaming", StrimmerSize+X, 60*num+15);//add "is streaming" after the name
      text( streamerData.get(index).streamTitle, X+10, 60*num+20, width/2-80, 40);//place title but don't let it be wider than half the screen            
      image(streamerData.get(index).profileImage, X-65, 60*num, 50, 50);//profile image
      //TWITCH_BASE_URL + streamerData.get(livenum).username, 200, 60*livenum+45;//this is here for later if I add an IRC bot
    } 
  }
}

// Produces a 'tick' every WAIT_TIME milliseconds
boolean clockTick() {
  return millis() - startTime > WAIT_TIME;
}


// Return the URL correctly formatted with queryParams.
String getUrlWithQueryParams(String url, String field) {
  for (String user : usernames) {
    url += field + "=" + user + "&";
  }
 
  return url;
}
