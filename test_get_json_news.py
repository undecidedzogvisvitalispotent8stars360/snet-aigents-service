import sys
import grpc
import json
from google.protobuf.json_format import MessageToJson

sys.path.append("./service_spec")
import aigents_pb2 as pb2
import aigents_pb2_grpc as pb2_grpc

def user_login(channel, email, sec_q, sec_a):
    stub = pb2_grpc.AigentsNewsFeedStub(channel)
    user_info = pb2.UserInfo()
    user_info.email = email
    user_info.secret_question = sec_q
    user_info.secret_answer = sec_a
    response = stub.userLogin(user_info)
    response = MessageToJson(response)
    response = json.loads(response)
    result = response['text']
    #print(result)
    return result

def get_news_feed(channel, name):
    stub = pb2_grpc.AigentsNewsFeedStub(channel)
    ch = pb2.Channel()
    ch.name = name
    response = stub.reqJSON(ch)
    response = MessageToJson(response)
    response = json.loads(response)
    #print(type(response))
    news = response['newsFeed']
    #print(news)
    return news


with grpc.insecure_channel('localhost:9999') as channel:
    user_login(channel, "amante@gmail.com", "when", "everyday")
    #user_login(channel, "aigents@icog-labs.com", "abebe", "beso")
    get_news_feed(channel, 'ai')
