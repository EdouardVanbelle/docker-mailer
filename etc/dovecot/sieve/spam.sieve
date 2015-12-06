require ["fileinto"];
# rule:[bogofilter spam]
if header :contains "X-Bogosity" "Spam,"
{
        fileinto "Spam";
}
# rule:[bogofilter unsure]
if header :contains "X-Bogosity" "Unsure,"
{
        fileinto "Unsure";
}
