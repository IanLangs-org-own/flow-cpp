#include <string>
#include <cctype>

static bool isIdent(char c) {
    return std::isalnum((unsigned char)c) || c == '_';
}

std::string transpile(const std::string& code) {
    std::string out;
    size_t i = 0, n = code.size();
    bool any_in_code = false;
    bool str_in_code = false;

    bool in_string = false;
    bool in_char = false;
    bool in_line_comment = false;
    bool in_block_comment = false;
    bool in_include = false;

    auto is_escaped = [&](size_t pos) {
        size_t count = 0;
        while (pos > 0 && code[pos - 1] == '\\') {
            count++;
            pos--;
        }
        return (count % 2) == 1;
    };

    while (i < n) {
        char c = code[i];
        char next = (i + 1 < n) ? code[i + 1] : '\0';

        if ((!in_string && !in_char && !in_line_comment && !in_block_comment) &&
            code.compare(i, 8, "#include") == 0) {
            in_include = true;
        }

        if (in_include && c == '\n') in_include = false;
        if (in_line_comment && c == '\n') in_line_comment = false;

        if (in_block_comment && c == '*' && next == '/') {
            in_block_comment = false;
            out += "*/";
            i += 2;
            continue;
        }

        if (!in_string && !in_char && !in_line_comment && !in_block_comment) {
            if (c == '/' && next == '/') in_line_comment = true;
            else if (c == '/' && next == '*') in_block_comment = true;
        }

        if (!in_char && !in_line_comment && !in_block_comment && c == '"' && !is_escaped(i))
            in_string = !in_string;

        if (!in_string && !in_line_comment && !in_block_comment && c == '\'' && !is_escaped(i))
            in_char = !in_char;

        if (!(in_string || in_char || in_line_comment || in_block_comment || in_include)) {

            // [expr]:Type:   or   [expr]:Type:?
            if (c == '[') {
                size_t j = i + 1;
                int depth = 1;

                while (j < n && depth > 0) {
                    if (code[j] == '[') depth++;
                    else if (code[j] == ']') depth--;
                    j++;
                }

                if (depth == 0 && j < n && code[j] == ':' ) {
                    size_t type_start = j + 1;
                    size_t k = type_start;

                    while (k < n && code[k] != ':' && code[k] != '\n') k++;

                    if (k < n && code[k] == ':') {
                        bool is_verify = (k + 1 < n && code[k + 1] == '?');

                        std::string expr = code.substr(i + 1, j - i - 2);
                        std::string type = code.substr(type_start, k - type_start);

                        if (is_verify) {
                            out += expr + ".type() == typeid(" + type + ")";
                            i = k + 2;
                        } else {
                            out += "std::any_cast<" + type + ">(" + expr + ")";
                            i = k + 1;
                        }

                        any_in_code = true;
                        continue;
                    }
                }
            }

            // any -> std::any
            if (code.compare(i, 3, "any") == 0) {
                char prev = (i > 0) ? code[i - 1] : '\0';
                char nextc = (i + 3 < n) ? code[i + 3] : '\0';
                bool in_other_scope = (i >= 2 && code[i - 2] == ':' && code[i - 1] == ':');

                if (!isIdent(prev) && !isIdent(nextc) && !in_other_scope) {
                    out += "std::any";
                    any_in_code = true;
                    i += 3;
                    continue;
                }
            }

            // str -> std::string
            if (code.compare(i, 3, "str") == 0) {
                char prev = (i > 0) ? code[i - 1] : '\0';
                char nextc = (i + 3 < n) ? code[i + 3] : '\0';
                bool in_other_scope = (i >= 2 && code[i - 2] == ':' && code[i - 1] == ':');

                if (!isIdent(prev) && !isIdent(nextc) && !in_other_scope) {
                    out += "std::string";
                    str_in_code = true;
                    i += 3;
                    continue;
                }
            }

            // Cfn -> extern "C"
            if (code.compare(i, 3, "Cfn") == 0) {
                char prev = (i > 0) ? code[i - 1] : '\0';
                char nextc = (i + 3 < n) ? code[i + 3] : '\0';
                bool in_other_scope = (i >= 2 && code[i - 2] == ':' && code[i - 1] == ':');

                if (!isIdent(prev) && !isIdent(nextc) && !in_other_scope) {
                    out += "extern \"C\"";
                    i += 3;
                    continue;
                }
            }
        }

        out += c;
        i++;
    }

    if (any_in_code && out.find("#include <any>") == std::string::npos) {
        size_t last_include = out.rfind("#include");
        if (last_include != std::string::npos) {
            size_t nl = out.find('\n', last_include);
            if (nl != std::string::npos) nl++;
            out.insert(nl, "#include <any>\n");
        } else {
            out = "#include <any>\n" + out;
        }
    }

    if (str_in_code &&
        out.find("#include <string>") == std::string::npos &&
        out.find("#include <iostream>") == std::string::npos) {

        size_t last_include = out.rfind("#include");
        if (last_include != std::string::npos) {
            size_t nl = out.find('\n', last_include);
            if (nl != std::string::npos) nl++;
            out.insert(nl, "#include <string>\n");
        } else {
            out = "#include <string>\n" + out;
        }
    }

    return out;
}