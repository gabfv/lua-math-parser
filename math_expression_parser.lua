function tokenizer(input)
    local position = 1
    local tokens = {}
    
    local patterns = {
        {pattern = "%s+", type = "whitespace"},
        {pattern = "[%-%−]?[%d%.]+", type = "number"},
        {pattern = "[*]", type = "multiply"},
        {pattern = "[/]", type = "divide"},
        {pattern = "[%+]", type = "add"},
        {pattern = "[%-%−]", type = "subtract"},
        {pattern = "[(]", type = "left_paren"},
        {pattern = "[)]", type = "right_paren"}
    }
    
    while position <= #input do
        local matched = false
        for _, patternInfo in ipairs(patterns) do
            local pattern, tokenType = patternInfo.pattern, patternInfo.type
            local start, finish = input:find("^" .. pattern, position)
            if start then
                if tokenType ~= "whitespace" then
                    table.insert(tokens, {type = tokenType, value = input:sub(start, finish)})
                end
                position = finish + 1
                matched = true
                break
            end
        end
        if not matched then
            error("Invalid input at position " .. position)
        end
    end
    
    return tokens
end

function consume(tokenType, tokens, current)
    if current > #tokens then return nil, current end
    if tokens[current].type == tokenType then
        current = current + 1
        return tokens[current - 1], current
    else
        return nil, current
    end
end

function primary(tokens, current)
    local token
    token, current = consume("number", tokens, current)
    if token then
        return tonumber(token.value), current
    end

    token, current = consume("left_paren", tokens, current)
    if token then
        local result
        result, current = expression(tokens, current)
        token, current = consume("right_paren", tokens, current)
        if not token then
            error("Missing closing parenthesis")
        end
        return result, current
    end

    error("Invalid input at token " .. current)
end

function factor(tokens, current)
    local left
    left, current = primary(tokens, current)
    while true do
        local mul, div
        mul, current = consume("multiply", tokens, current)
        div, current = consume("divide", tokens, current)
        if mul or div then
            local right
            right, current = primary(tokens, current)
            if mul then
                left = left * right
            else
                left = left / right
            end
        else
            break
        end
    end
    return left, current
end

function expression(tokens, current)
    local left
    left, current = factor(tokens, current)
    while true do
        local add, sub
        add, current = consume("add", tokens, current)
        sub, current = consume("subtract", tokens, current)
        if add or sub then
            local right
            right, current = factor(tokens, current)
            if add then
                left = left + right
            else
                left = left - right
            end
        else
            break
        end
    end
    return left, current
end

function parse_expression(tokens)
    local current = 1
    return expression(tokens, current)
end


function evaluate(input)
    local tokens = tokenizer(input)
    result, current = parse_expression(tokens)
    return result
end

-- Test the evaluate function
print(evaluate("3+5")) -- Output: 8
print(evaluate("(3+5)*2")) -- Output: 16
print(evaluate("3+5*2")) -- Output: 13
print(evaluate("3*3-2/2")) -- Output: 8
print(evaluate(" 50 * 10")) -- Output: 500
print(evaluate("-50 *-10")) -- Output: 500
print(evaluate("-50 * 10")) -- Output: -500
print(evaluate(" 50 *-10")) -- Output: -500
print(evaluate(" 50 - -10")) -- Output: 60
print(evaluate(" 50 --10")) -- Output: 60
