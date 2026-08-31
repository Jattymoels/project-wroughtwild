#include "wroughtwild/json.h"

#include <cctype>
#include <cstdlib>
#include <fstream>
#include <sstream>

namespace wroughtwild::json {

namespace {

class Parser {
public:
    explicit Parser(const std::string& source) : src(source) {}

    ValuePtr parseDocument() {
        ValuePtr value = parseValue();
        skipWhitespace();
        if (pos != src.size()) fail("trailing characters after document");
        return value;
    }

private:
    const std::string& src;
    size_t pos = 0;

    [[noreturn]] void fail(const std::string& message) const {
        throw std::runtime_error("json: " + message + " at offset " + std::to_string(pos));
    }

    void skipWhitespace() {
        while (pos < src.size() && std::isspace(static_cast<unsigned char>(src[pos]))) ++pos;
    }

    char peek() {
        skipWhitespace();
        if (pos >= src.size()) fail("unexpected end of input");
        return src[pos];
    }

    void expect(char c) {
        if (peek() != c) fail(std::string("expected '") + c + "'");
        ++pos;
    }

    ValuePtr parseValue() {
        char c = peek();
        switch (c) {
        case '{': return parseObject();
        case '[': return parseArray();
        case '"': return parseString();
        case 't': case 'f': return parseBoolean();
        case 'n': return parseNull();
        default: return parseNumber();
        }
    }

    ValuePtr parseObject() {
        expect('{');
        auto value = std::make_shared<Value>();
        value->type = Type::Object;
        if (peek() == '}') { ++pos; return value; }
        while (true) {
            ValuePtr key = parseString();
            expect(':');
            value->members[key->text] = parseValue();
            char c = peek();
            if (c == ',') { ++pos; continue; }
            if (c == '}') { ++pos; break; }
            fail("expected ',' or '}' in object");
        }
        return value;
    }

    ValuePtr parseArray() {
        expect('[');
        auto value = std::make_shared<Value>();
        value->type = Type::Array;
        if (peek() == ']') { ++pos; return value; }
        while (true) {
            value->items.push_back(parseValue());
            char c = peek();
            if (c == ',') { ++pos; continue; }
            if (c == ']') { ++pos; break; }
            fail("expected ',' or ']' in array");
        }
        return value;
    }

    ValuePtr parseString() {
        expect('"');
        auto value = std::make_shared<Value>();
        value->type = Type::String;
        while (true) {
            if (pos >= src.size()) fail("unterminated string");
            char c = src[pos++];
            if (c == '"') break;
            if (c == '\\') {
                if (pos >= src.size()) fail("unterminated escape");
                char e = src[pos++];
                switch (e) {
                case '"': value->text += '"'; break;
                case '\\': value->text += '\\'; break;
                case '/': value->text += '/'; break;
                case 'b': value->text += '\b'; break;
                case 'f': value->text += '\f'; break;
                case 'n': value->text += '\n'; break;
                case 'r': value->text += '\r'; break;
                case 't': value->text += '\t'; break;
                case 'u': {
                    if (pos + 4 > src.size()) fail("truncated \\u escape");
                    unsigned code = std::strtoul(src.substr(pos, 4).c_str(), nullptr, 16);
                    pos += 4;
                    // Tuning files are ASCII; encode BMP code points as UTF-8.
                    if (code < 0x80) {
                        value->text += static_cast<char>(code);
                    } else if (code < 0x800) {
                        value->text += static_cast<char>(0xC0 | (code >> 6));
                        value->text += static_cast<char>(0x80 | (code & 0x3F));
                    } else {
                        value->text += static_cast<char>(0xE0 | (code >> 12));
                        value->text += static_cast<char>(0x80 | ((code >> 6) & 0x3F));
                        value->text += static_cast<char>(0x80 | (code & 0x3F));
                    }
                    break;
                }
                default: fail("unknown escape sequence");
                }
            } else {
                value->text += c;
            }
        }
        return value;
    }

    ValuePtr parseBoolean() {
        auto value = std::make_shared<Value>();
        value->type = Type::Boolean;
        if (src.compare(pos, 4, "true") == 0) { value->boolean = true; pos += 4; }
        else if (src.compare(pos, 5, "false") == 0) { value->boolean = false; pos += 5; }
        else fail("invalid literal");
        return value;
    }

    ValuePtr parseNull() {
        if (src.compare(pos, 4, "null") != 0) fail("invalid literal");
        pos += 4;
        return std::make_shared<Value>();
    }

    ValuePtr parseNumber() {
        size_t start = pos;
        if (pos < src.size() && (src[pos] == '-' || src[pos] == '+')) ++pos;
        while (pos < src.size() &&
               (std::isdigit(static_cast<unsigned char>(src[pos])) || src[pos] == '.' ||
                src[pos] == 'e' || src[pos] == 'E' || src[pos] == '-' || src[pos] == '+')) {
            // Sign characters are only valid immediately after an exponent marker.
            if ((src[pos] == '-' || src[pos] == '+') &&
                !(src[pos - 1] == 'e' || src[pos - 1] == 'E'))
                break;
            ++pos;
        }
        if (pos == start) fail("invalid number");
        auto value = std::make_shared<Value>();
        value->type = Type::Number;
        value->number = std::strtod(src.substr(start, pos - start).c_str(), nullptr);
        return value;
    }
};

} // namespace

ValuePtr parse(const std::string& source) {
    return Parser(source).parseDocument();
}

ValuePtr parseFile(const std::string& path) {
    std::ifstream stream(path, std::ios::binary);
    if (!stream) throw std::runtime_error("json: cannot open file " + path);
    std::ostringstream buffer;
    buffer << stream.rdbuf();
    return parse(buffer.str());
}

} // namespace wroughtwild::json
