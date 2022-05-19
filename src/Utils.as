string TrimStringLeft(string&in str) {
    string trimmed = "";
    bool add = false;
    int addi = 0;

    for (int i = 0; i < str.Length; i++) {
        if (str[i] != 32) {
            add = true;
        }

        if (add) {
            trimmed += " ";
            trimmed[addi++] = str[i];
        }
    }

    return trimmed;
}

string TrimStringRight(string&in str) {
    string trimmed = "";
    bool add = false;

    for (int i = str.Length-1; i >= 0; i--) {
        if (str[i] != 32) {
            add = true;
        }

        if (add) {
            trimmed = " " + trimmed;
            trimmed[0] = str[i];
        }
    }

    return trimmed;
}

string TrimString(string&in str) {
    return TrimStringRight(TrimStringLeft(str));
}
