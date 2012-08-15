use strict;

use IO::Socket::INET;
use CGI;
use Irssi;
use Irssi::Irc;

# THINGS WHAT ARE WRONG
#
# swallows urls if something goes wrong
#
# sometimes fails on realllly crazy urls e.g.
#   http://books.google.co.uk/books?id=QM3uQqDiAQIC&pg=PA24&dq=%22Bart+vs.+the+Space+Mutan+ts%22&hl=en&ei=Wb87Tr2MHY3u-gbh4oiUAg&sa=X&oi=book_result&ct=result&redir_esc=y#v=onepage&q=%22Bart%20vs.%20the%20Space%20Mutants%22&f=false

my @lastURLs;

sub getURL {
  my ($server, $msg, $nick, $addr, $target) = @_;
  my $isgd_api_request = "GET /create.php?format=simple&url=%s HTTP/1.1\r\nHost: is.gd\r\n\r\n";

  return unless $msg =~ /.*(https?:\/\/([^\/]+)[^\s]*)/;
  my @tokens = split(/ /, $msg);
  my $out;

  foreach (@tokens) {
    if ($_ =~ /.*(https?:\/\/([^\/]+)[^\s]*)/) {
      # we got a url
      my ($url, $domain) = ($1, $2);

      # leave short urls be
      if (length($url) < 30) {
        $out .= "$_ ";
        next;
      }

      my $sock = new IO::Socket::INET(
        PeerAddr => 'is.gd',
        PeerPort => 'http(80)',
        Proto    => 'tcp'
      ) or die "ERROR in Socket Creation : $!\n";

      my $request = sprintf($isgd_api_request, CGI::escape($url));
      my $data;

      $sock->send($request);
      $sock->recv($data, 1024);
      $sock->close();

      $data =~ /(http.*)\r\n/;

      $out .= "$1 ($domain) ";
      if (scalar(@lastURLs) > 5) {
        shift(@lastURLs);
      }
      push(@lastURLs, ([$1, $url]));
    } else {
      $out .= "$_ ";
    }
  }
  Irssi::signal_continue($server, $out, $nick, $addr, $target);
}

# list the last 5 shortened urls
sub lastShortURL {
  foreach my $pair (@lastURLs) {
    Irssi::print(@$pair[0] . ' - ' . @$pair[1]);
  }
}

Irssi::signal_add_first("message public", "getURL");
Irssi::signal_add_first("ctcp action", "getURL");
Irssi::command_bind("lastshorturls", "lastShortURL");
