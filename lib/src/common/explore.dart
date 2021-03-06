part of github.common;

class TrendingRepository {
  String rank;
  html.Element titleObject;
  String get title => titleObject.text;
  
  String get url => "https://github.com/${title}";
  String description;
}

Stream<TrendingRepository> _trendingRepos({String language, String since: "daily"}) {
  var url = "https://github.com/trending";
  
  if (language != null) url += "?l=${language}";
  
  if (since != null) url += language == null ? "?since=${since}" : "&since=${since}";
  
  var controller = new StreamController();
  
  GitHub.defaultClient().request(new http.Request(url)).then((response) {
    var doc = htmlParser.parse(response.body);
    var items = doc.querySelectorAll("li.repo-leaderboard-list-item.leaderboard-list-item");
    
    for (var item in items) {
      var repo = new TrendingRepository();
      repo.rank = item.querySelector("a.leaderboard-list-rank").text;
      repo.titleObject = item.querySelector("h2.repo-leaderboard-title").querySelector("a");
      var desc = item.querySelector("p.repo-leaderboard-description");
      
      if (desc == null) {
        repo.description = "No Description";
      } else {
        repo.description = desc.text;
      }
      
      controller.add(repo);
    }
    
    controller.close();
  });
  
  return controller.stream;
}

class ShowcaseInfo {
  String title;
  String description;
  String url;
}

class Showcase extends ShowcaseInfo {
  DateTime lastUpdated;
  List<ShowcaseItem> items;
}

class ShowcaseItem {
  String name;
  String url;
}

Future<Showcase> _showcase(ShowcaseInfo info) {
  var completer = new Completer();
  
  GitHub.defaultClient().request(new http.Request(info.url)).then((response) {
    var doc = htmlParser.parse(response.body);
    var showcase = new Showcase();
    
    var title = doc.querySelector(".collection-header").text;
    var lastUpdated = parseDateTime(doc.querySelector(".meta-info.last-updated").querySelector("time").attributes['datetime']);
    var page = doc.querySelector(".collection-page");
    
    var description = page.querySelector(".collection-description");
    
    showcase.description = description;
    showcase.lastUpdated = lastUpdated;
    showcase.title = title;
    showcase.items = [];
    
    var repos = page.querySelectorAll(".collection-repo");
    
    for (var repo in repos) {
      var repoTitle = repo.querySelector(".collection-repo-title");
      var path = repoTitle.querySelector("a").attributes['href'];
      var url = "https://githb.com${path}";
      var name = path.substring(1);
      
      var item = new ShowcaseItem();
      
      item.name = name;
      
      item.url = url;
      
      showcase.items.add(item);
    }
    
    completer.complete(showcase);
  });
  
  return completer.future;
}

Stream<ShowcaseInfo> _showcases() {
  var controller = new StreamController();
  
  Function handleResponse;
  
  handleResponse = (response) {
    var doc = htmlParser.parse(response.body);
    
    var cards = doc.querySelectorAll(".collection-card");
    
    for (var card in cards) {
      var title = card.querySelector(".collection-card-title").text;
      var description = card.querySelector(".collection-card-body").text;
      var img = card.querySelector(".collection-card-image");
      var url = "https://github.com" + img.attributes['href'];
      
      var showcase = new ShowcaseInfo();
      
      showcase
          ..title = title
          ..description = description
          ..url = url;
      
      controller.add(showcase);
    }
    
    var pag = doc.querySelector(".pagination");
    
    var links = pag.querySelectorAll("a");
    
    var linkNext = null;
    
    bool didFetchMore = false;
    
    for (var link in links) {
      if (link.text.contains("Next")) {
        didFetchMore = true;
        GitHub.defaultClient().request(new http.Request(link.attributes['href'])).then(handleResponse);
      }
    }
    
    if (!didFetchMore) {
      controller.close();
    }
  };
  
  GitHub.defaultClient().request(new http.Request("https://github.com/showcases")).then(handleResponse);
  
  return controller.stream;
}