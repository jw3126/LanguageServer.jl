function process(r::JSONRPC.Request{Val{Symbol("textDocument/documentSymbol")},DocumentSymbolParams}, server) 
    uri = r.params.textDocument.uri 
    doc = server.documents[uri]
    syms = SymbolInformation[]
    s = get_toplevel(doc, server, false)

    for (v, loc, uri1) in s.symbols
        if v.t == :Function
            id = string(Expr(v.val isa EXPR{CSTParser.FunctionDef} ? v.val.args[2] : v.val.args[1]))
        else
            id = string(v.id)
        end
        ws_offset = trailing_ws_length(get_last_token(v.val))
        loc1 = loc.start:loc.stop - ws_offset
        push!(syms, SymbolInformation(id, SymbolKind(v.t), Location(uri, Range(doc, loc1))))
    end
    
    response = JSONRPC.Response(get(r.id), syms) 
    send(response, server) 
end

function JSONRPC.parse_params(::Type{Val{Symbol("textDocument/documentSymbol")}}, params)
    return DocumentSymbolParams(params) 
end


function process(r::JSONRPC.Request{Val{Symbol("workspace/symbol")},WorkspaceSymbolParams}, server) 
    syms = SymbolInformation[]
    query = r.params.query
    for (uri, doc) in server.documents
        s = get_toplevel(doc, server, false)
        for (v, loc, uri1) in s.symbols
            if ismatch(Regex(query, "i"), string(v.id))
                if v.t == :Function
                    id = string(Expr(v.val isa EXPR{CSTParser.FunctionDef} ? v.val.args[2] : v.val.args[1]))
                else
                    id = string(v.id)
                end
                push!(syms, SymbolInformation(id, SymbolKind(v.t), Location(uri, Range(doc, loc))))
            end
        end
    end

    response = JSONRPC.Response(get(r.id), syms) 
    send(response, server) 
end

function JSONRPC.parse_params(::Type{Val{Symbol("workspace/symbol")}}, params)
    return WorkspaceSymbolParams(params) 
end
