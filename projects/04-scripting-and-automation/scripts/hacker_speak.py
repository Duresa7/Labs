"""Leetspeak converter and credit-card masker I wrote while learning scripting.

Swaps letters for look-alike digits and masks all but the last four digits of a
card number. This is the original version; ../README.md documents a bug in the
"unlimited replacements" path and the one-line fix for it.
"""


def main():
    user_text = input("Enter text to h4ck3r 5p34k: ")
    max_reps = int(input("Enter maximum number of replacements per character: ") or -1)
    if max_reps == -1:
        max_reps = None
    hacker_speak_text = hacker_speak(user_text, max_reps)
    print("Hacker Speak:", hacker_speak_text)
    credit_card_number = input("Enter your credit card number (Must be 16 digits): ")
    card_hide = credit_card(credit_card_number)
    print("The last 4 digits of your Credit Card is:", card_hide)


def hacker_speak(text, max=None):
    replacements = [('a', '4'), ('e', '3'), ('i', '1'), ('o', '0'), ('s', '5')]
    for old, new in replacements:
        text = text.replace(old, new, max)
    return text


def credit_card(card_number):
    if len(card_number) != 16 or not card_number.isdigit():
        return "Please enter a valid 16 credit card number."
    return '*' * 12 + card_number[-4:]


if __name__ == "__main__":
    main()
