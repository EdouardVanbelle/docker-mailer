require ["fileinto"];
# rule:[spam]
if anyof (header :contains "X-Bogosity" "Spam,", header :contains "X-Spam-Status" "Yes")
{
        fileinto "Junk";
}
