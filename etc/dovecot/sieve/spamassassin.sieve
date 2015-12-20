require ["fileinto"];
# rule:[spam]
if header :contains "X-Bogosity" "Spam"
{
        fileinto "Junk";
}
