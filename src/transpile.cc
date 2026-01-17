#include <string>
#include <regex>

std::string transpile(const std::string& code) {
    std::string out;
    size_t i = 0;
    size_t n = code.size();
    bool any_in_code = false;
    bool in_string = false;
    bool in_char = false;
    bool in_line_comment = false;
    bool in_block_comment = false;
    bool in_include = false;
    std::regex castP(R"(\[([^\]]+)\]:([^:\n]+):)");
    std::regex veryfyP(R"(\[([^\]]+)\]:([^:\n]+):\?)");

    while (i < n) {
        char c = code[i];
        char next = (i + 1 < n) ? code[i + 1] : '\0';

        if ((!in_string && !in_char && !in_line_comment && !in_block_comment) && code.compare(i, 8, "#include") == 0) {
            in_include = true;
        }

        
        if (in_include && c == '\n') {
            in_include = false;
        }

        
        if (in_line_comment && c == '\n') {
            in_line_comment = false;
        }

        
        if (in_block_comment && c == '*' && next == '/') {
            in_block_comment = false;
            out += "*/";
            i += 2;
            continue;
        }

        
        if (!in_string && !in_char && !in_line_comment && !in_block_comment) {
            if (c == '/' && next == '/') {
                in_line_comment = true;
            } else if (c == '/' && next == '*') {
                in_block_comment = true;
            }
        }

        
        if (!in_char && !in_line_comment && !in_block_comment && c == '"') {
            
            bool escaped = (i > 0 && code[i-1] == '\\');
            if (!escaped) in_string = !in_string;
        }

        
        if (!in_string && !in_line_comment && !in_block_comment && c == '\'') {
            bool escaped = (i > 0 && code[i-1] == '\\');
            if (!escaped) in_char = !in_char;
}

        
        if (!(in_string || in_char || in_line_comment || in_block_comment || in_include)) {
            if (c == '[') {
                std::smatch m;
                if (std::regex_search(code.cbegin()+i, code.cend(), m, veryfyP) && m.position() == 0) {
                    std::string expr = m[1].str();
                    std::string type = m[2].str();
                    out += expr + ".type() == typeid(" + type + ")";
                    any_in_code = true;
                    i += m.length();
                    continue;
                }
                else if (std::regex_search(code.cbegin()+i, code.cend(), m, castP) && m.position() == 0) {
                    std::string expr = m[1].str();
                    std::string type = m[2].str();
                    out += "std::any_cast<" + type + ">(" + expr + ")";
                    any_in_code = true;
                    i += m.length();
                    continue;
                }
            }
            else if (code.compare(i, 3, "any") == 0) {
                
                char prev = (i > 0) ? code[i - 1] : '\0';
                char next = (i + 3 < n) ? code[i + 3] : '\0';
                bool in_other_scope = (i >= 2 && code[i-2] == ':' && code[i-1] == ':');

                auto isIdent = [](char c) {
                    return std::isalnum(c) || c == '_';
                };

                if (!isIdent(prev) && !isIdent(next) && !in_other_scope) {
                    out += "std::any";
                    any_in_code = true;
                    i += 3;
                    continue;
                }
            }
        }

        out += c;
        i++;
    }
    if (out.find("#include <any>") == std::string::npos && any_in_code) {
        size_t last_include = out.rfind("#include");
        if (last_include != std::string::npos) {
            size_t nl = out.find('\n', last_include);
            if (nl != std::string::npos) nl++; 
            out.insert(nl, "#include <any>\n");
        } else {
            out = "#include <any>\n" + out; 
        }
    }
    return out;
}