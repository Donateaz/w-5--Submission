//
//  TwitterClient.swift
//  Twitter
//
//  Created by Donatea Zefi on 3/01/16
//  Copyright © 2016 Donatea. All rights reserved.
//

import UIKit
import BDBOAuth1Manager

class TwitterClient: BDBOAuth1SessionManager {
 
    static let sharedInstance = TwitterClient(baseURL: NSURL(string: "https://api.twitter.com"), consumerKey: "tE6H25uRgvvPdXD6azoJEN6m0", consumerSecret: "pGPpWigJbeMQRqIQbR2OmMjfKqIuTdJ2aPgfWl8TguE6J5kGuJ");
    
    var loginSuccess: (() -> ())?;
    var loginFailure: ((NSError) -> ())?;
    var loginCompletion: ((user: User?, error: NSError?) -> Void)?

    
    var buffer: Tweet?;
    var bufferComplete: (() -> ())?;
    
    func login(success: () -> (), failure: (NSError) -> ()){
        loginSuccess = success;
        loginFailure = failure;
        
        deauthorize();
        fetchRequestTokenWithPath("oauth/request_token", method: "GET", callbackURL: NSURL(string: "twitterDon://oauth")!, scope: nil, success: { (requestToken: BDBOAuth1Credential!) -> Void in
            print("Got token");
            
            let url = NSURL(string: "https://api.twitter.com/oauth/authorize?oauth_token="+requestToken.token)!;
            UIApplication.sharedApplication().openURL(url);
            
            }) { (error: NSError!) -> Void in
                print("error: \(error.localizedDescription)");
                self.loginFailure?(error);
        }
    }
    
    func logout() {
        User.currentUser = nil;
        deauthorize();
        
        NSNotificationCenter.defaultCenter().postNotificationName(User.userDidLogoutNotification, object: nil);
    }
    
    func handleOpenUrl(url: NSURL) {
        
        let requestToken = BDBOAuth1Credential(queryString: url.query);
        
        fetchAccessTokenWithPath("oauth/access_token", method: "POST", requestToken: requestToken, success: { (accessToken: BDBOAuth1Credential!) -> Void in
            self.currentAccount({ (user: User) -> () in
                    User.currentUser = user;
                    self.loginSuccess?();
                
                }, failure: { (error: NSError) -> () in
                    self.loginFailure?(error);
            });
            self.loginSuccess?();
        }) { (error: NSError!) -> Void in
            print("error: " + error.localizedDescription);
            self.loginFailure?(error);
        }
    }
    
    func currentAccount(success: (User) -> (), failure: (NSError) -> ()) {
        GET("1.1/account/verify_credentials.json", parameters: nil, progress: nil, success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let userDictionary = response as! NSDictionary;
                let user = User(dictionary: userDictionary);
                success(user);
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                print("error: \(error.localizedDescription)");
                failure(error);
        });
    }
    
    func homeTimeline(maxId: Int? = nil, success: ([Tweet]) -> (), failure: (NSError) -> ()) {
        var params = ["count": 10];
        if(maxId != nil) {
            params["max_id"] = maxId;
        }
        
        // dummy api to overcome rate limit problems:
        // https://tejen.net/sub/codepath/twitter/#home_timeline.json
        GET("1.1/statuses/home_timeline.json", parameters: params, progress: nil, success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            
            let dictionaries = response as! [NSDictionary];
            let tweets = Tweet.tweetsWithArray(dictionaries);
            
            success(tweets)
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                failure(error);
        })
    }
    
    func user_timeline(user: User, maxId: Int? = nil, success: ([Tweet]) -> (), failure: (NSError) -> ()) {
        var params = ["count": 10];
        params["user_id"] = user.id!;
        if(maxId != nil) {
            params["max_id"] = maxId;
        }
        
        GET("1.1/statuses/user_timeline.json", parameters: params, progress: nil, success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let dictionaries = response as! [NSDictionary];
                let tweets = Tweet.tweetsWithArray(dictionaries);
                
                success(tweets)
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                failure(error);
        })
    }
    
    func favorite(params: NSDictionary?, favorite: Bool, completion: (tweet: Tweet?, error: NSError?) -> (Void)={_,_ in }) {
        let endpoint = favorite ? "create" : "destroy";
        POST("1.1/favorites/\(endpoint).json", parameters: params, success: { (operation: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let tweet = Tweet(dictionary: response as! NSDictionary);
                completion(tweet: tweet, error: nil);
            }) { (operation: NSURLSessionDataTask?, error: NSError) -> Void in
                completion(tweet: nil, error: error);
        }
    }
    
    func retweet(params: NSDictionary?, retweet: Bool, completion: (tweet: Tweet?, error: NSError?) -> (Void)={_,_ in }) {
        let tweetID = params!["id"] as! Int;
        let endpoint = retweet ? "retweet" : "unretweet";
        POST("1.1/statuses/\(endpoint)/\(tweetID).json", parameters: params, success: { (operation: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let tweet = Tweet(dictionary: response as! NSDictionary);
                completion(tweet: tweet, error: nil);
            }) { (operation: NSURLSessionDataTask?, error: NSError) -> Void in
                completion(tweet: nil, error: error);
        }
    }
    
    func populateTweetByID(TweetID: Int, completion: (tweet: Tweet?, error: NSError?) -> (Void)={_,_ in }) {
        GET("1.1/statuses/show.json?id=\(TweetID)", parameters: nil, progress: nil, success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let dictionary = response as! NSDictionary;
            let tweet = Tweet(dictionary: dictionary);
            
            completion(tweet: tweet, error: nil);
        }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
            completion(tweet: nil, error: error);
        });
    }
    
    func populatePreviousTweets(tweet: Tweet, completion: (()->())?) {
        if(completion != nil) {
            bufferComplete = completion;
        }
        print("populating previous tweet for: ");
        print(tweet.TweetID);
        if(tweet.precedingTweetID != nil) {
            buffer = tweet;
            populateTweetByID(tweet.precedingTweetID!, completion: { (tweet, error) -> (Void) in
                self.buffer?.precedingTweet = tweet;
                self.populatePreviousTweets(tweet!, completion: nil);
            });
        } else {
            print("chain complete");
            self.buffer = nil;
            self.bufferComplete?();
        }
    }
    
    func publishTweet(text: String, replyToTweetID: NSNumber? = 0, success: (Tweet) -> ()) {
        // Warning: this'll create a live tweet with the given text on behalf of the current user!
        if(text == "") {
            return;
        }
        let params = ["status": text, "in_reply_to_status_id": Int(replyToTweetID!)];
        POST("1.1/statuses/update.json", parameters: params, success: { (operation: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let tweet = Tweet(dictionary: response as! NSDictionary);
            success(tweet);
            }) { (operation: NSURLSessionDataTask?, error: NSError) -> Void in
                
        }
    }

    
    func getUserByScreenname(screenname: NSString, success: (User) -> (), failure: (NSError) -> ()) {
        GET("1.1/users/lookup.json?screen_name=" + String(screenname), parameters: nil, progress: nil, success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let userDictionary = response as! [NSDictionary];
                let user = User(dictionary: userDictionary[0]);
                success(user);
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                print("error: \(error.localizedDescription)");
                failure(error);
        });
    }

}
