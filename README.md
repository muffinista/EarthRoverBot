This is the code for the twitter bot https://twitter.com/EarthRoverBot

Basically this bot roves around the planet, using Google Street View
images to display the trip. It can only go places where there is
street view data. The bot will move on its own, but can also accept
input via Twitter.

The bot made an original trip from Maine to California, and is
currently hanging out around Vladivostok, and I am thinking about
sending it all the way to Portugal, but I also might change my mind,
or just experiment with other ways of using the bot.

The original code was a total wreck of monolithic ruby that was all in
a single file. I spent a little time splitting it into models and
cleaning up the worst of the mess before publishing it to Github. The
main files to check out:

- EarthRoverBot.rb is the main bot code. It listens to the Twitter
Streaming API and posts activity to Twitter
- repl.rb is a simple REPL for testing and experimenting on the
  command-line. You can type your commands into the console to see
  what happens.
- rover.rb is the main model for the rover itself
- parser.rb handles parsing commands and turning them into actions
- navigator.rb contains code for figuring out how/where to move
- point.rb contains some code for actually performing moves and
  tracking location
- street_view_checker.rb is the code for determining if a given
  location is visible on Google Street View
