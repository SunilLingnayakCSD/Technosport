public class NumberToText {
    static final String ZERO = 'zero';

    // Define the terms used in the Indian numbering system
    private static Map<Integer, String> tens = new Map<Integer, String> {
        20 => 'twenty',
        30 => 'thirty',
        40 => 'forty',
        50 => 'fifty',
        60 => 'sixty',
        70 => 'seventy',
        80 => 'eighty',
        90 => 'ninety'
    };

    private static Map<Integer, String> smallNumbers = new Map<Integer, String> {
        0 => 'zero',
        1 => 'one',
        2 => 'two',
        3 => 'three',
        4 => 'four',
        5 => 'five',
        6 => 'six',
        7 => 'seven',
        8 => 'eight',
        9 => 'nine',
        10 => 'ten',
        11 => 'eleven',
        12 => 'twelve',
        13 => 'thirteen',
        14 => 'fourteen',
        15 => 'fifteen',
        16 => 'sixteen',
        17 => 'seventeen',
        18 => 'eighteen',
        19 => 'nineteen'
    };

    private static Map<Integer, String> modifiers = new Map<Integer, String> {
        1 => 'thousand ',
        2 => 'lakh ',
        3 => 'crore '
    };

    public static String convert(Integer value) {
        if (value == 0) return ZERO;

        String numberText = '';

        // Handle negative numbers
        if (value < 0) {
            numberText = 'negative ';
            value *= -1;
        }

        // Convert number to string
        String numberString = String.valueOf(value);

        // Split number into sets (crore, lakh, thousand, etc.)
        List<String> sets = new List<String>();

        if (numberString.length() > 7) {
            sets.add(numberString.substring(0, numberString.length() - 7)); // Crore
            sets.add(numberString.substring(numberString.length() - 7, numberString.length() - 5)); // Lakh
            sets.add(numberString.substring(numberString.length() - 5, numberString.length() - 3)); // Thousand
            sets.add(numberString.substring(numberString.length() - 3, numberString.length())); // Hundreds
        } else if (numberString.length() > 5) {
            sets.add(numberString.substring(0, numberString.length() - 5)); // Lakh
            sets.add(numberString.substring(numberString.length() - 5, numberString.length() - 3)); // Thousand
            sets.add(numberString.substring(numberString.length() - 3, numberString.length())); // Hundreds
        } else if (numberString.length() > 2) {
            sets.add(numberString.substring(0, numberString.length() - 2)); // Thousands
            sets.add(numberString.substring(numberString.length() - 2, numberString.length())); // Hundreds
        } else {
            sets.add(numberString); // Just hundreds
        }

        Integer setIndex = 1;

        // Iterate through each set to build the number text
        for (Integer i = 0; i < sets.size(); i++) {
            String thisSet = sets.get(i);
            if (thisSet != '0' && thisSet != '') {
                String setText = generateText(Integer.valueOf(thisSet));

                // Append the modifier based on the set index (thousands, lakhs, crores)
                if (setIndex == 4) {
                    numberText += setText + ' crore ';
                } else if (setIndex == 3) {
                    numberText += setText + ' lakh ';
                } else if (setIndex == 2) {
                    numberText += setText + ' thousand ';
                } else if (setIndex == 1) {
                    numberText += setText + ' ';
                }
            }
            setIndex++;
        }

        return numberText.trim();
    }

    // Method to generate the text for numbers less than 100
    private static String generateText(Integer value) {
        if (value < 100) {
            return generateTextForTwoDigits(value);
        }

        String numberText = '';

        // Calculate the number of hundreds
        Integer hundreds = value / 100;
        if (hundreds > 0) {
            numberText = smallNumbers.get(hundreds) + ' hundred';
        }

        // Calculate the leftover value (tens and ones)
        Integer leftOver = Math.mod(value, 100);
        if (leftOver > 0) {
            // For numbers above 100, add 'and' to separate the hundreds part
            numberText += ' and ' + generateTextForTwoDigits(leftOver);
        }

        return numberText.trim();
    }

    // Method to generate text for two-digit numbers
    private static String generateTextForTwoDigits(Integer value) {
        if (value < 20) {
            return smallNumbers.get(value);
        }

        // Round the value down to the nearest 10 and get the text representation
        Integer tensKey = (value / 10) * 10;
        String numberText = tens.get(tensKey);

        // Calculate the leftover value
        Integer leftOver = value - tensKey;

        if (leftOver > 0) {
            numberText += '-' + smallNumbers.get(leftOver);
        }

        return numberText.trim();
    }
}