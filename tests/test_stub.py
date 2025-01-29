from kiwixseeder.entrypoint import prepare_context


def test_no_args():
    prepare_context([])
    from kiwixseeder.context import Context

    context = Context.get()
    assert not context.all_good
