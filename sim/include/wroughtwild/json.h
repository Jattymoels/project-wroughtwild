#pragma once

// Minimal JSON reader for Wroughtwild tuning files.
// Supports objects, arrays, strings, numbers, booleans and null; enough for
// data/tuning/*.json without a third-party dependency (see AGENTS.md).

#include <map>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace wroughtwild::json {

class Value;
using ValuePtr = std::shared_ptr<Value>;

enum class Type { Null, Boolean, Number, String, Array, Object };

class Value {
public:
    Type type = Type::Null;
    bool boolean = false;
    double number = 0.0;
    std::string text;
    std::vector<ValuePtr> items;
    std::map<std::string, ValuePtr> members;

    bool isNull() const { return type == Type::Null; }

    bool asBool() const {
        require(Type::Boolean, "boolean");
        return boolean;
    }
    double asNumber() const {
        require(Type::Number, "number");
        return number;
    }
    int asInt() const { return static_cast<int>(asNumber()); }
    const std::string& asString() const {
        require(Type::String, "string");
        return text;
    }
    const std::vector<ValuePtr>& asArray() const {
        require(Type::Array, "array");
        return items;
    }
    const std::map<std::string, ValuePtr>& asObject() const {
        require(Type::Object, "object");
        return members;
    }

    // Object member access; get() throws when the key is missing,
    // find() returns nullptr instead.
    ValuePtr find(const std::string& key) const {
        require(Type::Object, "object");
        auto it = members.find(key);
        return it == members.end() ? nullptr : it->second;
    }
    const Value& get(const std::string& key) const {
        ValuePtr v = find(key);
        if (!v) throw std::runtime_error("json: missing key '" + key + "'");
        return *v;
    }

private:
    void require(Type expected, const char* name) const {
        if (type != expected)
            throw std::runtime_error(std::string("json: value is not a ") + name);
    }
};

// Parses a complete JSON document; throws std::runtime_error on malformed input.
ValuePtr parse(const std::string& source);

// Reads and parses a file; throws std::runtime_error when unreadable.
ValuePtr parseFile(const std::string& path);

} // namespace wroughtwild::json
