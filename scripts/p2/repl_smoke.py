#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import time


SUITES = {
    "quick": [
        ("print(6*7)", "42"),
        ('s="abc"; print(s+"def")', "abcdef"),
        ('m={"a":2,"b":5}; print(m["a"]+m["b"])', "7"),
        ("import math; print(math.sqrt(81))", "9"),
    ],
    "full": [
        ('run_file("/tests/p2/smoke_all.be")', "P2_SMOKE_PASS all"),
    ],
    "edge32": [
        ('run_file("/tests/p2/smoke_edge32_all.be")', "P2_SMOKE_PASS edge32_all"),
    ],
    "xmm-heap": [
        ("import p2", ""),
        ("print(type(p2.gc), p2.gc())", "function"),
        (
            'print(p2.heap_info()["pointer_window_bytes"], p2.heap_info()["psram_block_base"], p2.heap_info()["psram_block_bytes"], p2.heap_info()["main_inside_pointer_window"])',
            "16777216 16777216 16777216 true",
        ),
        ('baseline=p2.heap_info()["main"]', ""),
        ("batch=[]", ""),
        ("i=0", ""),
        (
            'while i<512 batch.push({"index":i,"payload":str(i)+":"+("x"*(384+(i%5)*16)),"pair":[i,i+1]}); i=i+1 end',
            "",
        ),
        ('print(size(batch), baseline-p2.heap_info()["main"], p2.heap_info()["main_crosses_block_window"])', "512"),
        ("batch=nil", ""),
        ("print(p2.gc())", "freed"),
        ('print(p2.heap_info()["main_crosses_block_window"], p2.heap_info()["main"]>=baseline-262144)', "false true"),
    ],
    "xmm-heap-cross": [
        ("import p2", ""),
        ("print(type(p2.gc), p2.gc())", "function"),
        ('baseline=p2.heap_info()["main"]', ""),
        ("batch=[]", ""),
        ("i=0", ""),
        ('while i<1280 batch.push(str(i)+":"+("z"*3584)); i=i+1 end', ""),
        (
            'print(size(batch), baseline-p2.heap_info()["main"]>4194304, p2.heap_info()["main_crosses_block_window"])',
            "1280 true false",
        ),
        ("batch=nil", ""),
        ("print(p2.gc())", "freed"),
        ('print(p2.heap_info()["main_crosses_block_window"], p2.heap_info()["main"]>=baseline-524288)', "false true"),
    ],
    "xmm-vm-probe": [
        ("import p2", ""),
        ("mem=p2.heap_info(); ps=p2.psram_info()", ""),
        (
            'print(mem["pointer_window_bytes"], mem["pointer_heap_limit"], mem["psram_block_base"], mem["psram_block_bytes"], mem["main_inside_pointer_window"])',
            "16777216 16777216 16777216 16777216 true",
        ),
        (
            'print(ps["pointer_window_bytes"], ps["pointer_heap_limit"], ps["cache_base"], ps["cache_bytes"], ps["access"])',
            "16777216 16777216 16777216 16777216 xmm+block",
        ),
        ("rz=p2.psram_cache_reset(); ci=p2.psram_cache_info()", ""),
        ('print(rz["ok"], rz["next"], rz["alloc_count"])', "true 16777216 0"),
        (
            'print(ci["available"], ci["base"], ci["limit"], ci["libstore_base"], ci["limit"]==ci["libstore_base"])',
            "true 16777216 32505856 32505856 true",
        ),
        ('cr=p2.psram_cache_reserve(64,"xmm-vm-probe")', ""),
        (
            'print(cr["ok"], cr["index"], cr["address"]>=ci["base"], cr["address"]+cr["size"]<=ci["limit"], cr["size"], cr["owner"], cr["libstore_base"]==ci["libstore_base"])',
            "true 0 true true 64 xmm-vm-probe true",
        ),
        ('ci2=p2.psram_cache_info(); ce=p2.psram_cache_entries(); cf=p2.psram_cache_find("xmm-vm-probe"); print(ci2["next"]==cr["next"], ci2["used"]>=64, ci2["free"]<ci["free"], ci2["alloc_count"], ci2["entry_count"], size(ce), size(cf))', "true true true 1 1 1 1"),
        ('print(ce[0]["address"]==cr["address"], ce[0]["size"], ce[0]["used"], ce[0]["owner"])', "true 64 0 xmm-vm-probe"),
        ('print(cf[0]["index"], cf[0]["address"]==cr["address"], cf[0]["used"], cf[0]["owner"])', "0 true 0 xmm-vm-probe"),
        ('cfl=p2.psram_cache_find_latest("xmm-vm-probe"); print(cfl["found"], cfl["index"], cfl["owner"])', "true 0 xmm-vm-probe"),
        ('cw=p2.psram_cache_write_entry(cr["index"],0,"cache"); print(cw["ok"], cw["index"], cw["owner"], cw["size"], cw["used"], cw["write_count"], cw["last_write_checksum"], p2.psram_cache_read_entry(cr["index"],0,5))', "true 0 xmm-vm-probe 5 5 1 500 cache"),
        ('cu=p2.psram_cache_entries(); print(cu[0]["used"], cu[0]["write_count"], cu[0]["last_write_offset"], cu[0]["last_write_size"], cu[0]["last_write_checksum"])', "5 1 0 5 500"),
        ('cv=p2.psram_cache_verify_entry(cr["index"]); print(cv["ok"], cv["has_write"], cv["expected"], cv["actual"], cv["owner"])', "true true 500 500 xmm-vm-probe"),
        ('rl=p2.psram_cache_release(cr["index"]); print(rl["released"], rl["next"]==ci["base"], rl["entry_count"])', "true true 0"),
        ('rr=p2.psram_cache_reserve(32,"xmm-vm-probe-reuse"); print(rr["ok"], rr["index"], rr["address"]==ci["base"], rr["size"])', "true 0 true 32"),
        ("lk0=p2.vm_lock_info()", ""),
        ('print(lk0["available"], lk0["failed"], lk0["acquires"], lk0["contentions"])', "true false 0 0"),
        ('probe=p2.vm_probe(0,p2.heap_info()["vm_partition_bytes"],"child_value=6*7")', ""),
        (
            'print(probe["partition_ready"], probe["selected"], probe["child_created"], probe["child_deleted"], probe["child_ran"])',
            "true true true true true",
        ),
        ('print(probe["child_run_result"], probe["child_stack_top"])', "0 0"),
        (
            'print(probe["wrong_free_delta"], probe["wrong_realloc_delta"], probe["vm_partition_current"])',
            "0 0 -1",
        ),
        (
            'print(p2.heap_info()["vm_partition_created"], p2.heap_info()["vm_partition_current"], p2.heap_info()["wrong_free_count"], p2.heap_info()["wrong_realloc_count"])',
            "1 -1 0 0",
        ),
        ('many=p2.vm_probe_many(2,p2.heap_info()["vm_partition_bytes"],"child_value=7*8")', ""),
        (
            'print(many["partition_ready_count"], many["selected_count"], many["child_created_count"], many["child_deleted_count"], many["child_ran_count"], many["child_run_ok_count"])',
            "2 2 2 2 2 2",
        ),
        (
            'print(many["child_stack_clean_count"], many["wrong_free_delta"], many["wrong_realloc_delta"], many["vm_partition_current"], many["first_failure_slot"], many["last_run_result"])',
            "2 0 0 -1 -1 0",
        ),
        (
            'print(p2.heap_info()["vm_partition_created"], p2.heap_info()["vm_partition_current"], p2.heap_info()["wrong_free_count"], p2.heap_info()["wrong_realloc_count"])',
            "2 -1 0 0",
        ),
        (
            'call=p2.vm_call_probe(2,p2.heap_info()["vm_partition_bytes"],"def add(a,b) return a+b end","add",19,23)',
            "",
        ),
        (
            'print(call["partition_ready"], call["selected"], call["child_created"], call["child_deleted"], call["function_found"])',
            "true true true true true",
        ),
        (
            'print(call["source_result"], call["call_result"], call["result_type"], call["result_int"])',
            "0 0 1 42",
        ),
        (
            'print(call["wrong_free_delta"], call["wrong_realloc_delta"], call["vm_partition_current"])',
            "0 0 -1",
        ),
        (
            'callstr=p2.vm_call_probe(3,p2.heap_info()["vm_partition_bytes"],"def label() return \\"child-ok\\" end","label")',
            "",
        ),
        ('print(callstr["source_result"], callstr["call_result"], callstr["result_type"], callstr["result_string"])', "0 0 4 child-ok"),
        (
            'print(callstr["wrong_free_delta"], callstr["wrong_realloc_delta"], callstr["vm_partition_current"])',
            "0 0 -1",
        ),
        (
            'callargs=p2.vm_call_probe(3,p2.heap_info()["vm_partition_bytes"],"def mix(a,b,c,d) if b && c==nil return a+str(d) end return \\"bad\\" end","mix","child-",true,nil,42)',
            "",
        ),
        (
            'print(callargs["source_result"], callargs["call_result"], callargs["result_type"], callargs["result_string"])',
            "0 0 4 child-42",
        ),
        (
            'print(callargs["arg_string_count"], callargs["arg_bool_count"], callargs["arg_nil_count"], callargs["arg_int_count"])',
            "1 1 1 1",
        ),
        (
            'print(callargs["wrong_free_delta"], callargs["wrong_realloc_delta"], callargs["vm_partition_current"])',
            "0 0 -1",
        ),
        ("info0=p2.vm_partition_info(0); info1=p2.vm_partition_info(1)", ""),
        ('print(info0["ready"], info1["ready"], info0["current"], info1["current"])', "true true -1 -1"),
        ('print(info0["bytes"]>0, info1["bytes"]>0, info0["free"]>0, info1["free"]>0)', "true true true true"),
        (
            'print(p2.heap_info()["vm_partition_capacity"]>=p2.heap_info()["vm_partition_created"], p2.heap_info()["vm_partition_free_capacity"]>=0)',
            "true true",
        ),
        (
            'print(p2.vm_copyable(nil)["ok"], p2.vm_copyable(true)["ok"], p2.vm_copyable(42)["ok"], p2.vm_copyable("ok")["ok"])',
            "true true true true",
        ),
        ("def vm_copyable_test_fn() return 1 end", ""),
        (
            'print(p2.vm_copyable([1])["ok"], p2.vm_copyable({"a":1})["ok"], p2.vm_copyable(vm_copyable_test_fn)["ok"])',
            "false false false",
        ),
        (
            'api=p2.vm_call(0,p2.heap_info()["vm_partition_bytes"],"def api_add(a,b) return a+b end","api_add",5,37)',
            "",
        ),
        ('print(api["source_result"], api["call_result"], api["result_type"], api["result_int"])', "0 0 1 42"),
        ('print(api["wrong_free_delta"], api["wrong_realloc_delta"], api["vm_partition_current"])', "0 0 -1"),
        ("def bridge_add(a,b) return a+b end", ""),
        (
            'bridge=p2.vm_call(0,p2.heap_info()["vm_partition_bytes"],"def bridge_add(a,b) return a+b end",bridge_add,13,29)',
            "",
        ),
        ('print(bridge["source_result"], bridge["call_result"], bridge["result_type"], bridge["result_int"])', "0 0 1 42"),
        ('print(bridge["wrong_free_delta"], bridge["wrong_realloc_delta"], bridge["vm_partition_current"])', "0 0 -1"),
        ("rel3=p2.vm_partition_release(3)", ""),
        ('print(rel3["released"], rel3["was_ready"], rel3["ready"], rel3["current"])', "true true false -1"),
        (
            'print(rel3["after_created"]<rel3["before_created"], rel3["after_total"]<rel3["before_total"], rel3["after_main"]>rel3["before_main"])',
            "true true true",
        ),
        (
            'again=p2.vm_call(3,p2.heap_info()["vm_partition_bytes"],"def api_add(a,b) return a+b end","api_add",20,22)',
            "",
        ),
        ('print(again["source_result"], again["call_result"], again["result_type"], again["result_int"])', "0 0 1 42"),
        ("rel3b=p2.vm_partition_release(3)", ""),
        ('print(rel3b["released"], rel3b["was_ready"], rel3b["ready"], rel3b["current"])', "true true false -1"),
        (
            'once=p2.vm_call_once(3,p2.heap_info()["vm_partition_bytes"],"def api_add(a,b) return a+b end","api_add",21,21)',
            "",
        ),
        ('print(once["source_result"], once["call_result"], once["result_type"], once["result_int"])', "0 0 1 42"),
        ('print(once["release_attempted"], once["released"], once["partition_ready_after"], once["vm_partition_current"])', "true true false -1"),
        (
            'print(once["release_after_created"]<once["release_before_created"], once["release_after_total"]<once["release_before_total"], once["release_after_main"]>once["release_before_main"])',
            "true true true",
        ),
        ("h=p2.vm_open(3,p2.heap_info()[\"vm_partition_bytes\"])", ""),
        ('print(h["partition_ready"], h["selected"], h["child_created"], h["active"], h["current"])', "true true true true -1"),
        ('e1=p2.vm_eval(3,"child_persist=10")', ""),
        ('print(e1["active"], e1["selected"], e1["run_result"], e1["stack_top"], e1["current"])', "true true 0 0 -1"),
        ('e2=p2.vm_eval(3,"child_persist=child_persist+32")', ""),
        ('print(e2["active"], e2["selected"], e2["run_result"], e2["stack_top"], e2["current"])', "true true 0 0 -1"),
        ('g=p2.vm_get(3,"child_persist")', ""),
        ('print(g["active"], g["selected"], g["found"], g["result_type"], g["result_int"], g["current"])', "true true true 1 42 -1"),
        ('efn=p2.vm_eval(3,"def child_add(a,b) return a+b+child_persist end")', ""),
        ('print(efn["active"], efn["selected"], efn["run_result"], efn["stack_top"], efn["current"])', "true true 0 0 -1"),
        ('inv=p2.vm_invoke(3,"child_add",10,20)', ""),
        ('print(inv["active"], inv["selected"], inv["function_found"], inv["call_result"], inv["result_type"], inv["result_int"], inv["current"])', "true true true 0 1 72 -1"),
        ('print(inv["wrong_free_delta"], inv["wrong_realloc_delta"], inv["child_stack_top"])', "0 0 0"),
        ("closed=p2.vm_close(3)", ""),
        ('print(closed["was_active"], closed["child_deleted"], closed["released"], closed["active"], closed["partition_ready_after"], closed["current"])', "true true true false false -1"),
        (
            'print(closed["release_after_created"]<closed["release_before_created"], closed["release_after_total"]<closed["release_before_total"], closed["release_after_main"]>closed["release_before_main"])',
            "true true true",
        ),
        ("h2=p2.vm_open(2,p2.heap_info()[\"vm_partition_bytes\"]); h3=p2.vm_open(3,p2.heap_info()[\"vm_partition_bytes\"])", ""),
        ('print(h2["active"], h3["active"], h2["current"], h3["current"])', "true true -1 -1"),
        ('m2=p2.vm_eval(2,"child_id=200"); m3=p2.vm_eval(3,"child_id=300")', ""),
        ('print(m2["run_result"], m3["run_result"], m2["current"], m3["current"])', "0 0 -1 -1"),
        ('m2b=p2.vm_eval(2,"child_id=child_id+21"); m3b=p2.vm_eval(3,"child_id=child_id+33")', ""),
        ('print(m2b["run_result"], m3b["run_result"], m2b["current"], m3b["current"])', "0 0 -1 -1"),
        ('f2=p2.vm_eval(2,"def bump(a) child_id=child_id+a return child_id end"); f3=p2.vm_eval(3,"def bump(a) child_id=child_id+a return child_id end")', ""),
        ('i2=p2.vm_invoke(2,"bump",5); i3=p2.vm_invoke(3,"bump",7)', ""),
        ('print(i2["result_int"], i3["result_int"], i2["current"], i3["current"])', "226 340 -1 -1"),
        ('g2=p2.vm_get(2,"child_id"); g3=p2.vm_get(3,"child_id")', ""),
        ('print(g2["result_int"], g3["result_int"], g2["current"], g3["current"])', "226 340 -1 -1"),
        ('print(p2.vm_partition_info(2)["ready"], p2.vm_partition_info(3)["ready"])', "true true"),
        ("c2=p2.vm_close(2); c3=p2.vm_close(3)", ""),
        ('print(c2["child_deleted"], c2["released"], c2["partition_ready_after"], c3["child_deleted"], c3["released"], c3["partition_ready_after"])', "true true false true true false"),
        ("lk1=p2.vm_lock_info()", ""),
        ('print(lk1["available"], lk1["failed"], lk1["acquires"]>0, lk1["contentions"]>=0)', "true false true true"),
    ],
    "xmm-vm-cog": [
        ("import p2", ""),
        ("lk0=p2.vm_lock_info()", ""),
        ('print(lk0["available"], lk0["failed"])', "true false"),
        ("h=p2.vm_open(2,p2.heap_info()[\"vm_partition_bytes\"])", ""),
        ('print(h["partition_ready"], h["selected"], h["child_created"], h["active"], h["current"])', "true true true true -1"),
        ('e=p2.vm_eval(2,"child_id=100; def bump(a) child_id=child_id+a return child_id end")', ""),
        ('print(e["active"], e["selected"], e["run_result"], e["stack_top"], e["current"])', "true true 0 0 -1"),
        ('cs=p2.vm_cog_start(2,"bump",9)', ""),
        ('print(cs["started"], cs["status"], cs["function_found"], cs["call_result"], cs["result_type"], cs["result_int"], cs["current"])', "true 2 true 0 1 109 -1"),
        ('post=p2.vm_get(2,"child_id")', ""),
        ('print(post["active"], post["selected"], post["found"], post["result_type"], post["result_int"], post["current"])', "true true true 1 109 -1"),
        ("closed=p2.vm_close(2)", ""),
        ('print(closed["was_active"], closed["child_deleted"], closed["released"], closed["active"], closed["partition_ready_after"], closed["current"])', "true true true false false -1"),
        ("lk1=p2.vm_lock_info()", ""),
        ('print(lk1["available"], lk1["failed"], lk1["acquires"]>0, lk1["contentions"]>=0)', "true false true true"),
    ],
    "xmm-cog-ping": [
        ("import p2", ""),
        ("ping=p2.vm_cog_ping(41)", ""),
        ('print(ping["started"], ping["status"], ping["result"], ping["raw_running"], ping["stack_freed"], ping["thread_mode"], ping["current"])', "true 2 83 false true true -1"),
        ("print(6*7)", "42"),
    ],
    "xmm-p2mem-native-cache": [
        ("import p2", ""),
        ("import p2mem", ""),
        ("rz=p2mem.native_cache_reset()", ""),
        ('print(rz["ok"], rz["entry_count"], rz["alloc_count"])', "true 0 0"),
        ('before=p2mem.native_cache(); print(before["available"], before["entry_count"], before["free"]>15000000)', "true 0 true"),
        ('r=p2mem.native_cache_reserve(96,"p2mem-smoke")', ""),
        ('print(r["ok"], r["index"], r["size"], r["owner"])', "true 0 96 p2mem-smoke"),
        ('found=p2mem.native_cache_find("p2mem-smoke"); print(size(found), found[0]["index"], found[0]["owner"])', "1 0 p2mem-smoke"),
        ('w=p2mem.native_cache_write(r["index"],8,"p2mem-cache"); print(w["ok"], w["index"], w["offset"], w["owner"], w["size"], w["used"], w["write_count"], w["last_write_checksum"])', "true 0 8 p2mem-smoke 11 19 1 1026"),
        ('print(p2mem.native_cache_read(r["index"],8,11))', "p2mem-cache"),
        ('mid=p2mem.native_cache(); print(mid["entry_count"], mid["used"]>=96, mid["entries"][0]["used"], mid["entries"][0]["write_count"], mid["entries"][0]["last_write_size"], mid["entries"][0]["last_write_checksum"], mid["entries"][0]["owner"])', "1 true 19 1 11 1026 p2mem-smoke"),
        ('stats=p2mem.stats(); cache=p2mem.cache(); print(stats["native_cache_items"], cache["native"]["entry_count"])', "1 1"),
        ('rel=p2mem.native_cache_release(r["index"]); print(rel["released"], rel["entry_count"], rel["next"]==before["base"])', "true 0 true"),
        ('blob=p2mem.native_cache_put("p2mem-blob","blob-data"); print(blob["ok"], blob["index"], blob["write"]["used"], blob["write"]["write_count"], blob["write"]["last_write_checksum"], p2mem.native_cache_get("p2mem-blob"))', "true 0 9 1 870 blob-data"),
        ('bv=p2mem.native_cache_verify_owner("p2mem-blob"); print(bv["ok"], bv["found"], bv["expected"], bv["actual"], bv["owner"])', "true true 870 870 p2mem-blob"),
        ('bg=p2mem.native_cache_get_verified("p2mem-blob"); print(bg["ok"], bg["found"], bg["verify"]["ok"], bg["value"])', "true true true blob-data"),
        ('bs=p2mem.native_cache_status("p2mem-blob"); print(bs["ok"], bs["found"], bs["verified"], bs["used"], bs["last_write_checksum"])', "true true true 9 870"),
        ('bp=p2mem.native_cache_put_verified("p2mem-verified","checked"); print(bp["ok"], bp["verified"], bp["verify"]["ok"], bp["write"]["last_write_checksum"], p2mem.native_cache_get_verified("p2mem-verified")["value"])', "true true true 711 checked"),
        ('blob2=p2mem.native_cache_put("p2mem-blob","new-data"); latest=p2mem.native_cache_find_latest("p2mem-blob"); print(blob2["ok"], latest["found"], latest["index"], latest["used"], p2mem.native_cache_get("p2mem-blob"))', "true true 1 8 new-data"),
        ('rep=p2mem.native_cache_replace("p2mem-blob","final-data"); print(rep["ok"], rep["replaced"], rep["release"]["released"], rep["index"], p2mem.native_cache_get("p2mem-blob"))', "true true true 1 final-data"),
        ('rv=p2mem.native_cache_replace_verified("p2mem-blob","verified-final"); print(rv["ok"], rv["verified"], rv["verify"]["ok"], rv["write"]["last_write_checksum"], p2mem.native_cache_get_verified("p2mem-blob")["value"])', "true true true 1415 verified-final"),
        ('hist=p2mem.native_cache_owner_history("p2mem-blob"); print(size(hist), hist[0]["index"], hist[1]["index"])', "2 0 1"),
        ('drop=p2mem.native_cache_release_owner_chain("p2mem-blob"); print(drop["ok"], drop["released_count"], size(drop["remaining"]))', "true 2 0"),
        ('src=p2mem.native_source_put_verified("demo","print(6*7)"); print(src["ok"], src["verified"], src["write"]["used"], src["write"]["last_write_checksum"])', "true true 10 821"),
        ('ss=p2mem.native_source_status("demo"); print(ss["ok"], ss["found"], ss["verified"], ss["used"], ss["last_write_checksum"])', "true true true 10 821"),
        ('sg=p2mem.native_source_get_verified("demo"); print(sg["ok"], sg["verify"]["ok"], sg["value"])', "true true print(6*7)"),
        ('sr=p2mem.native_source_release("demo"); print(sr["ok"], sr["released_count"], size(sr["remaining"]))', "true 1 0"),
        ('plan=p2mem.native_module_sources_plan(["p2mem"]); print(plan["ok"], plan["requested"], plan["found_count"], plan["missing_count"], plan["total_bytes"]>100, plan["total_reserved_bytes"]>=plan["total_bytes"], plan["cache_free"]>plan["total_reserved_bytes"], plan["will_fit"], plan["items"][0]["owner"])', "true 1 1 0 true true true true module-source:p2mem"),
        ('ms=p2mem.native_module_source_put_verified("p2mem"); print(ms["ok"], ms["found"], ms["verified"], ms["write"]["used"]>100)', "true true true true"),
        ('mt=p2mem.native_module_source_status("p2mem"); print(mt["ok"], mt["found"], mt["verified"], mt["used"]==ms["write"]["used"])', "true true true true"),
        ('mg=p2mem.native_module_source_get_verified("p2mem"); print(mg["ok"], mg["verify"]["ok"], size(mg["value"])==ms["write"]["used"])', "true true true"),
        ('mr=p2mem.native_module_source_release("p2mem"); print(mr["ok"], mr["released_count"], size(mr["remaining"]))', "true 1 0"),
        ('warm=p2mem.native_module_sources_warm_verified(["p2mem"]); print(warm["ok"], warm["requested"], warm["ok_count"], warm["fail_count"], warm["items"][0]["module"])', "true 1 1 0 p2mem"),
        ('wstat=p2mem.native_module_sources_status(["p2mem"]); print(wstat["ok"], wstat["requested"], wstat["ok_count"], wstat["missing_count"], wstat["items"][0]["verified"])', "true 1 1 0 true"),
        ('wr=p2mem.native_module_sources_release(["p2mem"]); print(wr["ok"], wr["requested"], wr["released_count"], wr["fail_count"])', "true 1 1 0"),
        ('wfit=p2mem.native_module_sources_warm_if_fits(["p2mem"]); print(wfit["ok"], wfit["warmed"], wfit["reason"], wfit["plan"]["will_fit"], wfit["warm"]["ok_count"])', "true true ok true 1"),
        ('wfr=p2mem.native_module_sources_release(["p2mem"]); print(wfr["ok"], wfr["released_count"], wfr["fail_count"])', "true 1 0"),
    ],
}

LINE_ENDINGS = {
    "cr": b"\r",
    "lf": b"\n",
    "crlf": b"\r\n",
}


def load_serial_module():
    try:
        import serial  # type: ignore

        return serial
    except ImportError:
        print("error: pyserial is required: python3 -m pip install pyserial", file=sys.stderr)
        raise SystemExit(2)


def decode(data: bytes) -> str:
    return data.decode("utf-8", errors="replace")


def read_until(ser, marker: bytes, timeout: float) -> bytes:
    deadline = time.monotonic() + timeout
    data = bytearray()
    while time.monotonic() < deadline:
        chunk = ser.read(256)
        if chunk:
            data.extend(chunk)
            if marker in data:
                return bytes(data)
        else:
            time.sleep(0.02)
    raise TimeoutError(f"timed out waiting for {marker!r}; saw:\n{decode(bytes(data))}")


def run_command(ser, command: str, expected: str, line_ending: bytes, prompt: bytes, timeout: float) -> str:
    ser.write(command.encode("utf-8") + line_ending)
    ser.flush()
    output = read_until(ser, prompt, timeout)
    text = decode(output)
    if expected and expected not in text:
        raise AssertionError(
            f"expected {expected!r} after command {command!r}; saw:\n{text}"
        )
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Berry P2 REPL smoke commands over serial.")
    parser.add_argument("--port", required=True, help="serial device, for example /dev/cu.usbserial-P97cvdxp")
    parser.add_argument("--baud", type=int, default=230400, help="serial baud rate")
    parser.add_argument("--suite", choices=sorted(SUITES), default="full")
    parser.add_argument(
        "--command",
        action="append",
        default=[],
        help="custom Berry command to run instead of a built-in suite; repeat for multiple commands",
    )
    parser.add_argument(
        "--expect",
        action="append",
        default=[],
        help="expected output substring for the matching --command; repeat to match commands",
    )
    parser.add_argument("--repeat", type=int, default=1, help="number of times to run the selected suite")
    parser.add_argument("--duration-sec", type=float, default=0.0, help="repeat the selected suite until at least this many seconds have elapsed")
    parser.add_argument("--sleep-sec", type=float, default=0.0, help="delay between repeated suite runs")
    parser.add_argument("--timeout", type=float, default=20.0, help="seconds to wait for each prompt")
    parser.add_argument("--startup-timeout", type=float, default=20.0, help="seconds to wait for the first prompt")
    parser.add_argument("--line-ending", choices=sorted(LINE_ENDINGS), default="cr")
    parser.add_argument("--prompt", default="berry>")
    parser.add_argument(
        "--no-wait-start",
        action="store_true",
        help="send commands immediately instead of waiting for the initial prompt",
    )
    args = parser.parse_args()

    serial = load_serial_module()
    prompt = args.prompt.encode("utf-8")
    line_ending = LINE_ENDINGS[args.line_ending]

    ser = serial.Serial()
    ser.port = args.port
    ser.baudrate = args.baud
    ser.timeout = 0.05
    ser.write_timeout = 2.0
    ser.dtr = False
    ser.rts = False
    with ser:
        ser.reset_input_buffer()
        if not args.no_wait_start:
            print(f"[p2-smoke] waiting for {args.prompt!r} on {args.port} at {args.baud}")
            text = decode(read_until(ser, prompt, args.startup_timeout))
            sys.stdout.write(text)
            if text and not text.endswith("\n"):
                sys.stdout.write("\n")

        repeat = max(1, args.repeat)
        deadline = time.monotonic() + args.duration_sec if args.duration_sec > 0 else None
        iteration = 0

        while True:
            iteration += 1
            if repeat > 1 or deadline is not None:
                print(f"[p2-smoke] iteration {iteration}")

            if args.command:
                commands = []
                for index, command in enumerate(args.command):
                    expected = args.expect[index] if index < len(args.expect) else ""
                    commands.append((command, expected))
            else:
                commands = SUITES[args.suite]

            for command, expected in commands:
                print(f"[p2-smoke] {command}")
                text = run_command(ser, command, expected, line_ending, prompt, args.timeout)
                sys.stdout.write(text)
                if text and not text.endswith("\n"):
                    sys.stdout.write("\n")

            if deadline is not None:
                if time.monotonic() >= deadline:
                    break
            elif iteration >= repeat:
                break

            if args.sleep_sec > 0:
                time.sleep(args.sleep_sec)

    label = "custom" if args.command else args.suite
    print(f"[p2-smoke] PASS {label} iterations={iteration}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
