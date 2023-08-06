require ["fileinto"];
# rule:[spamassassin]
if anyof (header :contains "X-Spam-Status" "Yes,")
{
        fileinto "Junk";
}
# rule:[bogofilter]
if allof (header :contains "X-Bogosity" "Spam,", not header :contains "x-spam-status" "USER_IN_WELCOMELIST")
{
        fileinto "Junk";
}
# rule:[unsure]
if allof (header :contains "X-Bogosity" "Unsure,", not header :contains "x-spam-status" "USER_IN_WELCOMELIST")
{
        fileinto "Unsure";
}
