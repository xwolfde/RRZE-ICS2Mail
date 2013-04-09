#!/usr/bin/perl -w

use utf8;
use DateTime;
use Text::WrapI18N qw(wrap);
use Encode;


binmode(STDOUT, ":utf8");


my $ICS_URL = 'http://groupware.fau.de/owa/calendar/RRZE_RS_Events@exch.fau.de/Kalender/calendar.ics';
    # URL to ICS file
my $RANGE_DAYS = 7;
    # Number of days from today, that are beeing looked for
my $mailto = 'rrze-aktuelles@lists.fau.de';
my $from = 'wolfgang.wiese@fau.de';
my $sendmail = '/usr/sbin/sendmail';
my $subject = 'Terminhinweise ';
my $TEXTINASCII = 1;
my @tage = ("Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag");
my @monate = ("Januar", "Februar", "Maerz", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember");
my $templates = {
    'text'  => 'single.txt',
    'html'  => 'single.html',
    'textrahmen'    => 'rahmen.txt',
    'htmlrahmen'    => 'rahmen.html'
    };
my $template_cache;

$data = parseData(getICS($ICS_URL),$RANGE_DAYS);
if ($data->{'events'}) {
    $output = createEventOutput($data->{'events'});
    if ($output->{'countevents'} > 0) {
	$output = createRangeOutput($output);
	sendMail($output);
    } else {
	print "No events in next $RANGE_DAYS days\n";
    }
    
} else {
    print "No events found";
}
exit;
###############################################################################
# Subs
###############################################################################
sub sendMail {
    my $data = shift;
    my $MIMEBOUNDARY = '==THIS=IS=A=BOUNDARY=MADE=WITH=LOVE=TO=PERL=AND=JAVA=SUCKS';

    open(MAIL,"|$sendmail -t") || die("Sendmail $sendmail was not found");
    print MAIL "To: $mailto\n";
    print MAIL "From: $from\n";
    print MAIL "Subject: $subject $data->{'subjectadd'}\n";
    #if ($TEXTINASCII) {
#	print MAIL "Content-Type: multipart/alternative; Boundary=\"$MIMEBOUNDARY\"\n";
#    } else {
	print MAIL "Content-Type: multipart/alternative; charset=\"utf-8\"; Boundary=\"$MIMEBOUNDARY\"\n";
 #   }
    print MAIL "Content-Transfer-Encoding: 8BIT\n";
    print MAIL "MIME-Version: 1.0\n\n";
    print MAIL "--$MIMEBOUNDARY\n";

    if ($TEXTINASCII) {
        print MAIL "Content-Transfer-Encoding: 7BIT\n";
        print MAIL "Content-Type: text/plain; charset=\"ISO-8859-1\"\n\n";
        print MAIL setasciichars($data->{'text'});
    } else {
        print MAIL "Content-Transfer-Encoding: 8BIT\n";
        print MAIL "Content-Type: text/plain; charset=\"utf-8\"\n\n";
        print MAIL "$data->{'text'}";
    }
   
    print MAIL "--$MIMEBOUNDARY\n";
    print MAIL "Content-Transfer-Encoding: 8BIT\n";
    print MAIL "Content-Type: text/html; charset=\"utf-8\"\n\n";
    print MAIL "$data->{'html'}";
    print MAIL "--$MIMEBOUNDARY--\n";
    close MAIL;
    print "Send mail to  $mailto\n";
    print "  Title:  $subject $data->{'subjectadd'}\n";
    
}
###############################################################################
sub createRangeOutput {
    my $data = shift;
    
    open(f1,"<$templates->{'textrahmen'}") || die("Could not read template file $templates->{'textrahmen'}");
	while(<f1>) {
	    $template_cache->{'textrahmen'} .= $_;
	}
    close f1;
    open(f1,"<$templates->{'htmlrahmen'}") || die("Could not read template file $templates->{'htmlrahmen'}");
	while(<f1>) {
	    $template_cache->{'htmlrahmen'} .= $_;
	}
    close f1;

    my $dtstart = DateTime->now;
    my $dtend = DateTime->now;
    $dtend->add( {"days" => $RANGE_DAYS });
    my $tmplhash;


    $tmplhash->{'rangestart-wochentag'} = $tage[$dtstart->day_of_week-1];
    $tmplhash->{'rangestart-monatsname'} = $monate[$dtstart->month-1];
    $tmplhash->{'rangestart-day'} = $dtstart->day();;
    $tmplhash->{'rangestart-tag'} = $dtstart->day();;
    $tmplhash->{'rangestart-month'} = $dtstart->month();;
    $tmplhash->{'rangestart-year'} = $dtstart->year();;
    $tmplhash->{'rangestart-minute'} = $dtstart->minute();;
    $tmplhash->{'rangestart-hour'} = $dtstart->hour();;
    if (length($tmplhash->{'rangestart-hour'}) <2) {
	$tmplhash->{'rangestart-hour'} = '0'.$tmplhash->{'rangestart-hour'};
    }
    if (length($tmplhash->{'rangestart-minute'}) <2) {
	$tmplhash->{'rangestart-minute'} = '0'.$tmplhash->{'rangestart-minute'};
    }
    if (length($tmplhash->{'rangestart-day'}) <2) {
	$tmplhash->{'rangestart-day'} = '0'.$tmplhash->{'rangestart-day'};
    }
    if (length($tmplhash->{'rangestart-month'}) <2) {
	$tmplhash->{'rangestart-month'} = '0'.$tmplhash->{'rangestart-month'};
    }
    $tmplhash->{'rangestart-woche'} = $dtstart->week_number;

    $tmplhash->{'rangeend-wochentag'} = $tage[$dtend->day_of_week-1];
    $tmplhash->{'rangeend-monatsname'} = $monate[$dtend->month-1];
    $tmplhash->{'rangeend-day'} = $dtend->day();
    $tmplhash->{'rangeend-tag'} = $dtend->day();
    $tmplhash->{'rangeend-month'} = $dtend->month();;
    $tmplhash->{'rangeend-year'} = $dtend->year();;
    $tmplhash->{'rangeend-minute'} = $dtend->minute();;
    $tmplhash->{'rangeend-hour'} = $dtend->hour();
    if (length($tmplhash->{'rangeend-hour'}) <2) {
	$tmplhash->{'rangeend-hour'} = '0'.$tmplhash->{'rangeend-hour'};
    }
    if (length($tmplhash->{'rangeend-minute'}) <2) {
	$tmplhash->{'rangeend-minute'} = '0'.$tmplhash->{'rangeend-minute'};
    }
    if (length($tmplhash->{'rangeend-day'}) <2) {
	$tmplhash->{'rangeend-day'} = '0'.$tmplhash->{'rangeend-day'};
    }
    if (length($tmplhash->{'rangeend-month'}) <2) {
	$tmplhash->{'rangeend-month'} = '0'.$tmplhash->{'rangeend-month'};
    }
    $tmplhash->{'rangeend-woche'} = $dtend->week_number;    


    my $htmlout = $template_cache->{'htmlrahmen'};
    my $textout = $template_cache->{'textrahmen'};
    my $that;
    foreach $key (keys %{$tmplhash}) {
	$that = $tmplhash->{$key};
	$htmlout =~ s/#$key#/$that/gi;
	$textout =~ s/#$key#/$that/gi;
    }
    $that = $data->{'html'};
    $htmlout =~ s/#events#/$that/gi;
    $that = $data->{'text'};
    $textout =~ s/#events#/$that/gi;

    my $result;
    $result->{'html'} = $htmlout;
    $result->{'text'} = $textout;

    $result->{'subjectadd'} =  $tmplhash->{'rangestart-day'}.".". $tmplhash->{'rangestart-month'}.".". $tmplhash->{'rangestart-year'};
    return $result;
}
###############################################################################
sub createEventOutput {
    my $events = shift;
    my $type = shift; 
    my $year;
    my $month;
    my $day;
    my $uid;
    my $key;
    my $this;
    my $index;
    $this->{'countevents'} =0;
    foreach $year (sort {$a<=>$b} keys %{$events}) {
	 foreach $month (sort {$a<=>$b} keys %{$events->{$year}}) {
	     foreach $day (sort {$a<=>$b} keys %{$events->{$year}->{$month}}) {
		foreach $uid (sort keys %{$events->{$year}->{$month}->{$day}}) {		    
		    $this->{'text'} .= creatSingleEventOutput($events->{$year}->{$month}->{$day}->{$uid},'text');
		    $this->{'html'} .= creatSingleEventOutput($events->{$year}->{$month}->{$day}->{$uid},'html');
		    $index->{$uid} = correctStrings($events->{$year}->{$month}->{$day}->{$uid}->{'SUMMARY'});
		    $this->{'countevents'}++;
		} 
	    } 
	 }    	
    }
    if ($index) { $this->{'index'} =  $index; }
    return $this;
}
###############################################################################
sub creatSingleEventOutput {
    my $single = shift;
    my $type = shift; 
    return if (not $single);

    my $result;
    my $titel = $single->{'SUMMARY'};
    my $dtstart = DateTime;
    my $dtend = DateTime;
    $dtstart = $single->{'DTSTART'};
    $dtend = $single->{'DTEND'};   

    $tmplhash->{'title'} = correctStrings($single->{'SUMMARY'});
    $tmplhash->{'summary'} = correctStrings($single->{'SUMMARY'});
    $tmplhash->{'location'} = correctStrings($single->{'LOCATION'});
    $tmplhash->{'description'} = correctStrings($single->{'DESCRIPTION'});
    $tmplhash->{'uid'} = $single->{'UID'};

    $tmplhash->{'dtstart-wochentag'} = $tage[$dtstart->day_of_week-1];
    $tmplhash->{'dtstart-monatsname'} = $monate[$dtstart->month-1];
    $tmplhash->{'dtstart-day'} = $dtstart->day();;
    $tmplhash->{'dtstart-tag'} = $dtstart->day();;
    $tmplhash->{'dtstart-month'} = $dtstart->month();;
    $tmplhash->{'dtstart-year'} = $dtstart->year();;
    $tmplhash->{'dtstart-minute'} = $dtstart->minute();;
    $tmplhash->{'dtstart-hour'} = $dtstart->hour();;
    if (length($tmplhash->{'dtstart-hour'}) <2) {
	$tmplhash->{'dtstart-hour'} = '0'.$tmplhash->{'dtstart-hour'};
    }
    if (length($tmplhash->{'dtstart-minute'}) <2) {
	$tmplhash->{'dtstart-minute'} = '0'.$tmplhash->{'dtstart-minute'};
    }
    if (length($tmplhash->{'dtstart-day'}) <2) {
	$tmplhash->{'dtstart-day'} = '0'.$tmplhash->{'dtstart-day'};
    }
    if (length($tmplhash->{'dtstart-month'}) <2) {
	$tmplhash->{'dtstart-month'} = '0'.$tmplhash->{'dtstart-month'};
    }
    $tmplhash->{'dtstart-woche'} = $dtstart->week_number;

    $tmplhash->{'dtend-wochentag'} = $tage[$dtend->day_of_week-1];
    $tmplhash->{'dtend-monatsname'} = $monate[$dtend->month-1];
    $tmplhash->{'dtend-day'} = $dtend->day();
    $tmplhash->{'dtend-tag'} = $dtend->day();
    $tmplhash->{'dtend-month'} = $dtend->month();;
    $tmplhash->{'dtend-year'} = $dtend->year();;
    $tmplhash->{'dtend-minute'} = $dtend->minute();;
    $tmplhash->{'dtend-hour'} = $dtend->hour();
    if (length($tmplhash->{'dtend-hour'}) <2) {
	$tmplhash->{'dtend-hour'} = '0'.$tmplhash->{'dtend-hour'};
    }
    if (length($tmplhash->{'dtend-minute'}) <2) {
	$tmplhash->{'dtend-minute'} = '0'.$tmplhash->{'dtend-minute'};
    }
    if (length($tmplhash->{'dtend-day'}) <2) {
	$tmplhash->{'dtend-day'} = '0'.$tmplhash->{'dtend-day'};
    }
    if (length($tmplhash->{'dtend-month'}) <2) {
	$tmplhash->{'dtend-month'} = '0'.$tmplhash->{'dtend-month'};
    }
    $tmplhash->{'dtend-woche'} = $dtend->week_number;    
   
    return creatSingleEventOutputRef($tmplhash,$type);
}
###############################################################################
sub correctStrings {
    my $string = shift;
    $string =~ s/\\,/,/gi;
    $string =~ s/\\;/,/gi;
    $string =~ s/\\n/\n/gi;
    return $string;
}
###############################################################################
sub creatSingleEventOutputRef {
    my $data = shift;
    my $type = shift;
    
    $type = 'text' if (not $type);
    
    if (not $template_cache->{$type}) {
	open(f1,"<$templates->{$type}") || die("Could not read template file $templates->{$type}");
	while(<f1>) {
	    $template_cache->{$type} .= $_;
	}
	close f1;
    }
    my $out = $template_cache->{$type};
    my $key;
    my $that;

    foreach $key (keys %{$data}) {
	$that = $data->{$key};
	if ($type eq 'html') {
	    $that =~ s/\n/<br>\n/gi;
	}
	$out =~ s/#$key#/$that/gi;
    }

    if ($type eq 'text') {
	$out = wrap("","",$out);

    }
    return $out;
}
###############################################################################
sub parseData {
    my $string = shift;
    my $range = shift || 7;

    return if (not $string);

   
    my $dt = DateTime->now;
    my $fromdate = $dt->ymd;
    $fromdate =~ s/\-//gi;
    $dt->add( {"days" => $range });
    my $todate = $dt->ymd; 
    $todate =~ s/\-//gi;    
    my %args = ("start"=>$fromdate, "end"=>$todate,"no_todos"=>1);
    use iCal::Parser;
    my $parser=iCal::Parser->new(%args);
    my $combined= $parser->parse_strings($string);
    if (not $combined) {
	die("No data by iCal");
    }
    return $combined;
}
###############################################################################
sub getICS {
    my $url = shift;
    return if (not $url);
    use LWP::Simple;
    $content = get($url);
    utf8::encode($content);
    $content =~ s/\r\n //gi;
  
    if (not $content) {
	die("No content from URL $url");
    }
    return $content;
}
###############################################################################
sub setasciichars {
    my $text = shift;
 Encode::from_to($text, "utf8", "iso-8859-1"); 

        $text =~ s/ä/ae/g;
        $text =~ s/Ä/Ae/g;
        $text =~ s/ö/oe/g;
        $text =~ s/Ö/Oe/g;
        $text =~ s/ü/ue/g;
        $text =~ s/Ü/Ue/g;
        $text =~ s/ß/ss/g;
        $text =~ s/„/"/g;
        $text =~ s/“/"/g;
        $text =~ s/«/"/g;
        $text =~ s/»/"/g;
        $text =~ s/€/EURO/g;
        $text =~ s/©/(C)/g;

               

    return $text;
}
###############################################################################
