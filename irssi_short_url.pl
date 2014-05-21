use strict;

use IO::Socket::INET;
use CGI;

use Irssi;

use vars qw($VERSION %IRSSI);

$VERSION = "0.1";
%IRSSI = (
  authors     => 'Reece Selwood',
  contact     => 'contact@alligatr.co.uk',
  name        => 'Short URL',
  description => 'Shortern long URLs using is.gd.',
  url         => 'https://github.com/Alligator/irssi-short-url',
  license     => 'MIT'
);

# a lil script to shorten long URLs so they're easier to open if they break
# lines. uses http://is.gd/ by default.
#
# /set shorturl_url <url>
# /set shorturl_params <params>
#
#   these are both sent to curl in the form:
#     curl <url> -s -d <params>
#   where %s in the params is replace by the URL to be shortened.
#
# /set shorturl_respre <regex>
#   this is the regex used to parse out the url. for example if the api you're
#   using returns the bare url it should be (.*).

my %CONFIG;

sub init {
  %CONFIG = (
    url    => Irssi::settings_get_str("shorturl_url"),
    params => Irssi::settings_get_str("shorturl_params"),
    respre => Irssi::settings_get_str("shorturl_respre"),
  );
  if (!length $CONFIG{url}) {
    $CONFIG{url} = "http://bombch.us/shorten/new";
    Irssi::print("shorturl_url not set, defaulting to $CONFIG{url}");
  }
  if (!length $CONFIG{params}) {
    $CONFIG{params} = "url=%s";
    Irssi::print("shorturl_params not set, defaulting to $CONFIG{params}");
  }
  if (!length $CONFIG{respre}) {
    $CONFIG{respre} = '"url":"([^"]*)\"';
    Irssi::print("shorturl_respre not set, defaulting to $CONFIG{respre}");
  }
}

my @lastURLs;

sub getURL {
  my ($server, $msg, $nick, $addr, $target) = @_;
  return unless $msg =~ /.*(https?:\/\/([^\/]+)[^\s]*)/;
  my @tokens = split(/ /, $msg);
  my $out;
  foreach (@tokens) {
    if ($_ =~ /.*(https?:\/\/([^\/]+)[^\s]*)/) {
      # we got a url
      my ($url, $domain) = ($1, $2);

      # leave short urls be
      if (length($url) <= 30) {
        $out .= "$_ ";
        next;
      }

      my $posturl = $CONFIG{url};
      my $params = $CONFIG{params};

      $params = sprintf($params, CGI::escape($url));

      my $short = `/usr/bin/curl "$posturl" -s -d "$params"`;
      return unless $short =~ /.*(https?:\/\/([^\/]+)[^\s]*)/;
      $short =~ /$CONFIG{respre}/;

      $out .= "$1 ($domain) ";
      if (scalar(@lastURLs) > 5) {
        shift(@lastURLs);
      }
      push(@lastURLs, ([$1, $short]));
    } else {
      $out .= "$_ ";
    }
  }
  Irssi::signal_continue($server, $out, $nick, $addr, $target);
}

# list the last 5 shortened urls, just in case it eats something.
sub lastShortURL {
  foreach my $pair (@lastURLs) {
    Irssi::print(@$pair[0] . ' - ' . @$pair[1]);
  }
}

Irssi::settings_add_str("shorturl", "shorturl_url", '');
Irssi::settings_add_str("shorturl", "shorturl_params", '');
Irssi::settings_add_str("shorturl", "shorturl_respre", '');

init();

Irssi::signal_add_first("message public", "getURL");
Irssi::signal_add_first("ctcp action", "getURL");
