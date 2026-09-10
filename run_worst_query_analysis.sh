#!/usr/bin/env bash
# Edit these 6 lines for the run you want, then just run this file.
TEST_DB=basketball
CARD_TYPE=act
MODEL_DIR=saved/models/aug_act_complex_dd_pulluppushdown_ddestfonudf_liboh_gradnorm_mldupl_loopend_loopedge_basketball_bs512_ep100_maxr30_augpoolmax_augrefgated_residual_augcl1_augnoRET_cfl0.25
MODEL_NAME=aug_act_complex_dd_pulluppushdown_ddestfonudf_liboh_gradnorm_mldupl_loopend_loopedge_basketball_bs512_ep100_maxr30_augpoolmax_augrefgated_residual_augcl1_augnoRET_cfl0.25_20260909_185342_082
POOLING=max
COARSE_LAYERS=1

python find_worst_queries.py --test_db $TEST_DB --card_type $CARD_TYPE --model_config ddestfonudf_liboh_gradnorm_mldupl_loopend_loopedge --model_dir $MODEL_DIR --model_name $MODEL_NAME --augment_pooling $POOLING --augment_coarse_layers $COARSE_LAYERS --device cuda:0 --top_n 50 --best_n 50

RUN_STAMP=$(grep -oE '[0-9]{8}_[0-9]{6}_[0-9]{3}$' <<<"$MODEL_NAME")
QUERIES_CSV=results/worst_queries/${TEST_DB}_${RUN_STAMP}_worst50_best50.csv
python analyze_refinement_similarity.py --test_db $TEST_DB --card_type $CARD_TYPE --model_config ddestfonudf_liboh_gradnorm_mldupl_loopend_loopedge --model_dir $MODEL_DIR --model_name $MODEL_NAME --augment_pooling $POOLING --augment_coarse_layers $COARSE_LAYERS --queries_csv $QUERIES_CSV --device cuda:0 && rm $QUERIES_CSV
